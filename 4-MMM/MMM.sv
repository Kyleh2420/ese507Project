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
    logic [$clog2(DEPTH+1)-1:0] fifoCapacity;

    //State Logic
    enum {waitForLoad, compute, stall} currentState;

    //Internal signals used to determine current status
    logic [K_BITS-1:0] K;
    logic [M-1:0] outputRow;
    logic [N-1:0] outputCol;

    input_mems #(INW, M, N, MAXK) inputMem(
        .clk(clk),
        .reset(reset),
        .AXIS_TDATA(INPUT_TDATA)
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

    always_comb begin : dataPath
        case (currentState)
            waitForLoad: begin
                aAddress = 0;
                bAddress = 0;
            end
            compute: begin
                aAddress = index + (outputRow * K);
                bAddress = (index * K) + outputCol;
            end
            stall: begin
                //When we stall, the items here can remain the same. 
                //We just set the valid_input line to 0 to signal the mac to not do anything
                aAddress = index + (outputRow * K);
                bAddress = (index * K) + outputCol;
            end
        endcase  
    end

    //This entire thing could be made more effiient by writing the stalling when we're done computing, instead of as we're computing
    //In other words, check for stall when we're about to write (get to either index, outputCol, or outputRow hitting their respective maximums)
    //That way, even if the processor stalls, we can continue accumulating. 
    //However, right now I just want to get something working, and therefore am just doing it as simple as possible -- stall anytime the fifo is full

    always_ff @(posedge clk) begin : controlPath
    case (currentState)
            waitForLoad: begin

                //Logic Signals
                computeFinished <= 0;
                index <= 0;
                outputRow <= 0;
                outputCol <= 0;
                fifoWriteEnable <= 0;
                clearAcc <= 1;
                validInput <= 0;

                //State control logic
                if (matricesLoaded == 1) begin
                    currentState <= compute;
                    //maybe place validInput here?
                end else begin
                    currentState <= waitForLoad;
                end

            end
            compute: begin
                computeFinished <= 0;
                currentState <= compute;    //State stays in compute, onless oetherwise noted

                //The following should only be computed if we're not going to overwrite anything
                if (fifoCapacity == 0) begin
                    if (index == K-1) begin
                        //In here, we are done computing the dot product (Incremented past all K values)
                        //Thus, we should choose something to increment - either the column or the row
                        if (outputCol == N-1) begin
                            //In here, we're done computing the entire output row (done with all columns in a row). Increment to the next row, or check if we're finished with this computation
                            if (outputRow == M-1) begin
                                //In here, we're basically done computing the entire matrix. Move back to the waitForLoad state and set computeFinished to 1
                                currentState <= waitForLoad;
                                fifoWriteEnable <= 1;
                                computeFinished <= 1;
                            end else begin
                                index <= 0;
                                outputCol <= outputCol + 1;
                                
                                // I don't know if we need this here to remove an implied lach
                                outputRow <= outputRow;
                                fifoWriteEnable <= 1;
                                clearAcc <= 1;
                                validInput <= 1;
                            end
                        end else begin
                            //In here, we're not yet done computing the entire row (We're still computing some columns in the row.) Increment to the next column
                            index <= 0;
                            outputCol <= 0;
                            outputRow <= outputRow + 1;
                            fifoWriteEnable <= 1;
                            clearAcc <= 1;
                            validInput <= 1;

                        end
                    end else begin
                        //In here, we are not yet done computing the dot product. Increment index
                        index <= index + 1;

                        //The following may be necessary to rid an implied latch, but I'm not entirely sure right now
                        //outputRow <= outputRow;
                        //outputCol <= outputCol;

                        fifoWriteEnable <= 0;
                        clearAcc <= 0;
                        validInput <= 1;

                    end
                end else begin
                    currentState = stall;
                end
            end
            stall: begin
                if (fifoCapacity != 0) begin
                    //fifo is no longer full. Go back to compute
                    currentState <= compute;
                end else begin
                    //Fifo is still full. Remain in stall
                    currentState <= stall;
                end
            end
        endcase 
    end
endmodule