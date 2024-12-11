module MMM #(
        parameter INW = 12,
        parameter OUTW = 32,
        parameter M = 7,
        parameter N = 9,
        parameter MAXK = 8,
        localparam K_BITS = $clog2(MAXK+1),
        localparam mulStage = 4
    )(
        input clk,
        input reset,
        input [INW-1:0] INPUT_TDATA,
        input INPUT_TVALID,
        input [K_BITS:0] INPUT_TUSER,
        output INPUT_TREADY,
        output [OUTW-1:0] OUTPUT_TDATA,
        output OUTPUT_TVALID,
        input OUTPUT_TREADY
    );


    //Named nets between the modules, to help keep things organized
    //Utilized to "pipe" data around, controlled by the overall FSM

    //input_mems logic
    logic matricesLoaded, computeFinished;
    logic [K_BITS-1:0] K;
    logic [$clog2(M*MAXK)-1:0] aAddress;
    logic [$clog2(MAXK*N)-1:0] bAddress;
    logic signed [INW-1:0] aData, bData;

    //mac_pipe logic
    logic signed [OUTW-1:0] macOut;
    logic clearAcc, validInput;

    //fifo logic
    logic fifoWriteEnable;
    logic [$clog2(N+1)-1:0] fifoCapacity;

    //State Logic
    enum {waitForLoad, compute, stall} currentState, nextState;

    //Internal signals used to determine current status
    logic [K_BITS-1:0] index;
    logic [M-1:0] outputRow;
    logic [N-1:0] outputCol;


    //Used to delay the clear accumulate signal by one additional clock
    logic clearAccTrigger, fifoWriteTrigger, validInputTrigger; 
    logic clearAccDelay1,  fifoWriteEnableDelay1;

    //Used to pipeline the mac unit
    logic [3:0] writeCount; //The number of write signals that have been issued
    logic [6:0] fifoWrEnDelay;
    logic [6:0] clearAccDelay;
    logic [4:0] validDelay;


    input_mems_buffer2x #(INW, M, N, MAXK) inputMem(
    // input_mems #(INW, M, N, MAXK) inputMem(
        .clk(clk),
        .reset(reset),
        .AXIS_TDATA(INPUT_TDATA),
        .AXIS_TVALID(INPUT_TVALID),
        .AXIS_TUSER(INPUT_TUSER),
        .AXIS_TREADY(INPUT_TREADY),
        .matrices_loaded(matricesLoaded),
        .compute_finished(computeFinished),
        .K(K),
        .A_read_addr(aAddress),
        .A_data(aData),
        .B_read_addr(bAddress),
        .B_data(bData)
    );

    mac_pipe #(INW, OUTW) mac(
        .in0(aData), 
        .in1(bData),
        .out(macOut),
        .clk(clk), 
        .reset(reset), 
        .clear_acc(clearAcc),
        .valid_input(validInput)
    );

    fifo_out #(OUTW, N) fifo(
        .clk(clk),
        .reset(reset),
        .data_in(macOut),
        .wr_en(fifoWriteEnable),
        .capacity(fifoCapacity),
        .AXIS_TDATA(OUTPUT_TDATA),
        .AXIS_TVALID(OUTPUT_TVALID),
        .AXIS_TREADY(OUTPUT_TREADY)
    );


    //Used to create the shift register
    always_comb begin
        clearAcc <= clearAccDelay[0];
        fifoWriteEnable <= fifoWrEnDelay[0];
        validInput <= validDelay[0];

        //count the number of 1s in the fifoWriteEnable
        writeCount = 0;
        for (int i = 0; i < 5; i++) begin
            writeCount += fifoWrEnDelay[i];
        end

    end
    
    always_ff @(posedge clk) begin : delayAccumulateClear

        // //The original code
        // clearAcc <= clearAccDelay1;
        // clearAccDelay1 <= clearAccTrigger;
        // fifoWriteEnable <= fifoWriteEnableDelay1;
        // fifoWriteEnableDelay1 <= fifoWriteTrigger;

        if(reset == 1) begin
            for (int i = 6; i >0; i = i-1) begin
                clearAccDelay[i] <= 0;
                fifoWrEnDelay[i] <= 0;
            end 
        end

        for (int i = mulStage; i >0; i = i-1) begin
            clearAccDelay[i-1] <= clearAccDelay[i];
            fifoWrEnDelay[i-1] <= fifoWrEnDelay[i];
        end

        for (int j = mulStage-1; j >0; j = j-1) begin
            validDelay[j-1] <= validDelay[j];
        end

        clearAccDelay[mulStage] <= clearAccTrigger;
        fifoWrEnDelay[mulStage] <= fifoWriteTrigger;
        validDelay[mulStage-2] <= validInputTrigger;

    end

    //Datapath stuff
    always_comb begin: dataPath
        case (currentState)
            waitForLoad: begin
                aAddress = 0;
                bAddress = 0;
            end
            compute: begin
                aAddress = index + (outputRow * K);
                bAddress = (index * N) + outputCol;
            end
            stall: begin
                aAddress = index + (outputRow * K);
                bAddress = (index * N) + outputCol;
            end
            default: begin
                //Removing the inferred latch
                aAddress = 0;
                bAddress = 0;
            end
        endcase
    end

    //Used to check if we can write to the fifo
    // logic writePipeline;

    //NextState Logic
    always_comb begin : nextStateLogic

        //Used in the compute state to see if there is any space at all;
        // writePipeline = fifoWriteEnable;

        if (reset == 1) begin
            nextState <= waitForLoad;
        end else begin
            case (currentState)
            waitForLoad: begin
                if (matricesLoaded == 1) begin
                    nextState <= compute;
                end else begin
                    nextState <= waitForLoad;
                end
            end
            compute: begin
                //As long as we can write to the outputFIFO, continue computing. Unless it is full, then move to state stall
                //We also count as full if the capacity is 1 and we're about to write to the fifo (Check fifoWriteDelay and fifoWriteDelay1)
                if (fifoCapacity == 0 || (writeCount == fifoCapacity)) begin
                    //There is no space in the fifo -- stall
                    nextState <= stall;
                end else begin
                    if (computeFinished) begin
                        nextState <= waitForLoad;
                    end else begin
                        nextState <= compute;
                    end
                end
            end
            stall: begin
                if (fifoCapacity == 0 || (writeCount == fifoCapacity)) begin
                    //Fifo is full -- continue stalling
                    nextState <= stall;
                end else begin
                    //Fifo is no longer full -- go back to computing
                    nextState <= compute;
                end
            end
            default: begin
                //Removing the inferred latch
                nextState <= waitForLoad;
            end
            endcase
        end
    end

    always_ff @( posedge clk ) begin : controlSignals

    currentState <= nextState;

        //Defaults for the control signals
        computeFinished <= 0;
        index <= index;
        outputRow <= outputRow;
        outputCol <= outputCol;
        fifoWriteTrigger <= 0;
        clearAccTrigger <= 0;
        validInputTrigger <= 0;

        case (currentState)
            waitForLoad: begin
                index <= 0;
                outputCol <= 0;
                outputRow <= 0;
                computeFinished <= 0;
                clearAccTrigger <= 1;
            end
            compute: begin
                if (index == K-1) begin
                    //In this block, we are done computing the dot product.
                    //Choose something else to increment and reset K to the beginning
                    if (outputCol == N-1) begin
                        //In this block, we are done computing the entire output row. Increment to the next row, or check if we're done with the computation alltogether
                        if (outputRow == M-1) begin
                            //In this block, we're done computing the entire matrix. move to waitForFinish to ensure a response form input_mems
                            

                            //If the next state is waitForLoad, then this has been acknowleged. Drop computeFinished back to 0
                            if (nextState == waitForLoad) begin
                                computeFinished <= 0;
                                fifoWriteTrigger <= 0;
                                clearAccTrigger <= 1;
                                validInputTrigger <= 0;
                            end else if (nextState != stall) begin
                                //In addition, check to make sure we're not going to stall out 
                                computeFinished <= 1;
                                fifoWriteTrigger <= 1;
                                clearAccTrigger <= 1;
                                validInputTrigger <= 1;
                            end
                        end else begin
                            //In this block, we're not done computing the matrix. Increment to the next row

                            //if nextState == stall, dont' do anything. Otherwise, continue as normal
                            if (nextState != stall) begin
                                index <= 0;
                                outputRow <= outputRow + 1;
                                outputCol <= 0;
                                fifoWriteTrigger <= 1;
                                clearAccTrigger <= 1;
                                validInputTrigger <= 1;
                            end
                        end
                    end else begin
                        //In this block, we're not yet done computing the output row. Increment outputCol.

                        //If nextState == stall, don't do anything. Otherwise, continue as normal
                        if (nextState != stall) begin
                            index <= 0;
                            outputRow <= outputRow;
                            outputCol <= outputCol + 1;
                            fifoWriteTrigger <= 1;
                            clearAccTrigger <= 1;
                            validInputTrigger <= 1;
                        end
                    end
                end else begin
                    //Dot product is not done computing. Increment K and continue going.
                    index <= index + 1;
                    fifoWriteTrigger <= 0;
                    clearAccTrigger <= 0;
                    validInputTrigger <= 1;
                end
            end
            stall: begin
                fifoWriteTrigger <= 0;
                clearAccTrigger <= 0;
                validInputTrigger <= 0;
            end
        endcase
    end

endmodule