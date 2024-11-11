module memory #(
        parameter WIDTH=16, SIZE=64,
        localparam LOGSIZE=$clog2(SIZE)
    )(
        input [WIDTH-1:0] data_in,
        output logic [WIDTH-1:0] data_out,
        input [LOGSIZE-1:0] addr,
        input clk, wr_en
    );
    logic [SIZE-1:0][WIDTH-1:0] mem;

    always_ff @(posedge clk) begin
        data_out <= mem[addr];

        if (wr_en)
            mem[addr] <= data_in;
    end
endmodule

module input_mems #(
        parameter INW = 12,
        parameter M = 7,
        parameter N = 9,
        parameter MAXK = 8,
        localparam K_BITS = $clog2(MAXK+1),
        localparam A_ADDR_BITS = $clog2(M*MAXK),
        localparam B_ADDR_BITS = $clog2(MAXK*N)
    )(
        input clk, reset,
        input [INW-1:0] AXIS_TDATA,
        input AXIS_TVALID,
        input [K_BITS:0] AXIS_TUSER,
        output logic AXIS_TREADY,
        output logic matrices_loaded,
        input compute_finished,
        output logic [K_BITS-1:0] K,
        input [A_ADDR_BITS-1:0] A_read_addr,
        output logic signed [INW-1:0] A_data,
        input [B_ADDR_BITS-1:0] B_read_addr,
        output logic signed [INW-1:0] B_data
    );

    //Logic symbols to assist in seperating out newA and K from the line AXIS_TUSER
    logic new_A;
    assign new_A = AXIS_TUSER[0];

    logic [$clog2(MAXK+1)-1:0] TUSER_K;
    assign TUSER_K = AXIS_TUSER[$clog2(MAXK+1):1];

    //Enumeration to control states
    enum {takeInFirst, takeInData, memRead} currentState, nextState;


    //Named nets between the memory modules (Just to keep things organized)
    logic[INW-1:0] aDataIn, bDataIn, aDataOut, bDataOut;
    logic[A_ADDR_BITS-1:0] aAddress;
    logic[B_ADDR_BITS-1:0] bAddress;
    logic aWriteEnable, bWriteEnable;

    //"Local Variables" 
    //This variable stores the current address being written to by the takeInData stage
    //The max value should be A_addr_bits or B_Addr_bits
    logic [A_ADDR_BITS-1:0] aCurrentAddress;
    logic [B_ADDR_BITS-1:0] bCurrentAddress;
    //This variable stores the value of T User A (If the value being read should go into Matrix A or Matrix B)
    logic localA;
    //This variable stores the value of K (The shared parameter between Matrix A [MxK] and Matrix B[KxN])
    logic [K_BITS-1:0] localK;
    

    //Memory instantiation for both A and B
    memory #(INW,A_ADDR_BITS) matrixA(
        .data_in(aDataIn),
        .data_out(aDataOut),
        .addr(aAddress),
        .clk(clk),
        .wr_en(aWriteEnable)
    );
    memory #(INW,B_ADDR_BITS) matrixB(
        .data_in(bDataIn),
        .data_out(bDataOut),
        .addr(bAddress),
        .clk(clk),
        .wr_en(bWriteEnable)
    );

    always_ff @(posedge clk) begin
        if (reset == 1) begin
            //Code to reset everything back to 0
            //Reset state to waitForValid
            currentState = takeInFirst;
        end else begin 
            //Everything in this if block should be wrapped in another if statement, which ensures TVALID is 1
            //State stuff goes here
            currentState = nextState;

            unique case (currentState)

                takeInFirst: begin                    
                    //Set current addresses to 1 because we are already working with address = 0
                    bCurrentAddress = 1;
                    aCurrentAddress = 1;

                    //First check if the data stream is ready and valid
                    if (AXIS_TVALID == 1) begin
                        //Update local variables
                        localA = new_A;
                        localK = TUSER_K;

                        //If new_A = 1, we have to load the new A Matrix. Else, we load in B Matrix
                        if (new_A == 1) begin
                            
                            //First assert wr_en for A Matrix
                            aWriteEnable = 1;
                            bWriteEnable = 0;

                            //Load first bit of new A Matrix
                            aDataIn = AXIS_TDATA;

                        end else begin
                            
                            //Assert wr_en for B Matrix
                            bWriteEnable = 1;
                            aWriteEnable = 0;

                            //Load first bit of B Matrix
                            bDataIn = AXIS_TDATA;
                        end

                        nextState = takeInData;
                        AXIS_TREADY = 1;
                        matrices_loaded = 0;

                    end else begin
                        nextState = takeInFirst;
                    end

                    

                end

                takeInData: begin
                    //Take in data stuff goes here
                    //This state should taken in data for every clock cycle and store it into the address indicated to by 'currentAddress'.
                    //The max of currentAddress is inidated by A_ADDR_BITS-1 or B_ADDR_BITS-1 depending on the value of newA
                    //if newA = 1, then the address refers to matrix A
                    //if newA = 0, then the address refers to matrix B
                    //Then, increment currentAddress

                    //aCurrentAddress and bCurrentAddress have been set to 1 by the FSM in state takeInFirst
                    AXIS_TREADY = 1;

                    //On each clock cycle, the data is only valid if AXIS_TVALID is set to 1 and AXIS_TREADY is set to 1
                    if (AXIS_TVALID == 1) begin
                        if (localA == 0) begin
                            //This should handle matrixB shenanigans

                            //If the currentAddress = maxB, then move onto the next state, memRead
                            if (bCurrentAddress == (localK * M) - 1) begin 
                                nextState = memRead; 
                                bWriteEnable = 0;
                            end
                            else begin
                                nextState = takeInData;

                                //Store the data from AXIS_TDATA to the current address, then increment the current address
                                bWriteEnable = 1;
                                bDataIn = AXIS_TDATA;
                                bAddress = bCurrentAddress;
                                bCurrentAddress = bCurrentAddress + 1;
                            end
                        end else begin 
                            //This should handle matrixA shenanigans

                            //If the currentAddress = maxA, then set localA to 0, indicating that we should move to reading matrixB
                            if (aCurrentAddress == (localK * N) - 1) begin
                                localA = 0;
                                aWriteEnable = 0;   //Make sure to close off aWriteEnable
                            end else begin
                                nextState = takeInData;

                                //Store the data from AXIS_TDATA to the current address, then increment the current address
                                aWriteEnable = 1;
                                aDataIn = AXIS_TDATA;
                                aAddress = aCurrentAddress;
                                aCurrentAddress = aCurrentAddress + 1;
                            end
                        end
                    end
                end

                memRead: begin
                    //memory read stuff goes in here first
                    //This state changes when compute_finished = 1 and moves the FSM back to waitForValid
                    if (compute_finished == 1) begin
                        nextState = takeInFirst;
                        matrices_loaded = 0;
                        AXIS_TREADY = 1;
                    end else begin
                        //We cannot accept new data until compute_ready is done
                        AXIS_TREADY = 0;
                        matrices_loaded = 1;
                        K = localK;

                        aAddress = A_read_addr;
                        bAddress = B_read_addr;

                        A_data = aDataOut;
                        B_data = bDataOut;

                    end
                end 
            
            endcase
        end
    end
endmodule

