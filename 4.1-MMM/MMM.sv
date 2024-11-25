module MMM #(
        parameter INW = 12,
        parameter OUTW = 32,
        parameter M = 7,
        parameter N = 9,
        parameter MAXK = 8,
        localparam K_BITS = $clog2(MAXK+1)
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

    input_mems #(INW, M, N, MAXK) inputMem(
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

    //Used to delay the clear accumulate signal by one additional clock
    logic clearAccDelay1, clearAccDelay2, fifoWriteEnableDelay1, fifoWriteEnableDelay2, validDelay1;
    always_ff @(posedge clk) begin : delayAccumulateClear

        clearAcc <= clearAccDelay1;
        clearAccDelay1 <= clearAccDelay2;
        fifoWriteEnable <= fifoWriteEnableDelay1;
        fifoWriteEnableDelay1 <= fifoWriteEnableDelay2;
        // validInput <= validDelay1;
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
        endcase
    end

    //NextState Logic
    always_comb begin : nextStateLogic
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
                if (fifoCapacity == 0 || ((fifoWriteEnable == 1 || fifoWriteEnableDelay1 == 1) && fifoCapacity == 1)) begin
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
                if (fifoCapacity == 0 || ((fifoWriteEnable == 1 || fifoWriteEnableDelay1 == 1) && fifoCapacity == 1)) begin
                    //Fifo is full -- continue stalling
                    nextState <= stall;
                end else begin
                    //Fifo is no longer full -- go back to computing
                    nextState <= compute;
                end
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
        fifoWriteEnableDelay2 <= 0;
        clearAccDelay2 <= 0;
        validInput <= 0;

        case (currentState)
            waitForLoad: begin
                index <= 0;
                outputCol <= 0;
                outputRow <= 0;
                computeFinished <= 0;
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
                                fifoWriteEnableDelay2 <= 0;
                                clearAccDelay2 <= 0;
                                validInput <= 0;
                            end else if (nextState != stall) begin
                                //In addition, check to make sure we're not going to stall out 
                                computeFinished <= 1;
                                fifoWriteEnableDelay2 <= 1;
                                clearAccDelay2 <= 1;
                                validInput <= 1;
                            end
                        end else begin
                            //In this block, we're not done computing the matrix. Increment to the next row

                            //if nextState == stall, dont' do anything. Otherwise, continue as normal
                            if (nextState != stall) begin
                                index <= 0;
                                outputRow <= outputRow + 1;
                                outputCol <= 0;
                                fifoWriteEnableDelay2 <= 1;
                                clearAccDelay2 <= 1;
                                validInput <= 1;
                            end
                        end
                    end else begin
                        //In this block, we're not yet done computing the output row. Increment outputCol.

                        //If nextState == stall, don't do anything. Otherwise, continue as normal
                        if (nextState != stall) begin
                            index <= 0;
                            outputRow <= outputRow;
                            outputCol <= outputCol + 1;
                            fifoWriteEnableDelay2 <= 1;
                            clearAccDelay2 <= 1;
                            validInput <= 1;
                        end
                    end
                end else begin
                    //Dot product is not done computing. Increment K and continue going.
                    index <= index + 1;
                    fifoWriteEnableDelay2 <= 0;
                    clearAccDelay2 <= 0;
                    validInput <= 1;
                end
            end
            stall: begin
                fifoWriteEnableDelay2 <= 0;
                clearAccDelay2 <= 0;
                validInput <= 0;
            end
        endcase
    end

endmodule