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
    memory #(INW,(2**A_ADDR_BITS)) matrixA(
        .data_in(aDataIn),
        .data_out(aDataOut),
        .addr(aAddress),
        .clk(clk),
        .wr_en(aWriteEnable)
    );
    memory #(INW,(2**B_ADDR_BITS)) matrixB(
        .data_in(bDataIn),
        .data_out(bDataOut),
        .addr(bAddress),
        .clk(clk),
        .wr_en(bWriteEnable)
    );

    always_comb begin
        A_data = aDataOut;
        B_data = bDataOut;
        //We'll send this to both memory registers and hope and pray that the FSM will handle the enables correctly
        aDataIn = AXIS_TDATA;
        bDataIn = AXIS_TDATA;

        //This should create a MUX
        unique case (currentState)
            takeInFirst: begin
                //takeInFirst State
                matrices_loaded = 0;
                aAddress = aCurrentAddress;
                bAddress = bCurrentAddress;
                if (localA == 1 && AXIS_TVALID == 1) begin
                    aWriteEnable = 1;
                    bWriteEnable = 0;
                end else begin
                    aWriteEnable = 0;
                    bWriteEnable = 1;
                end

            end 
                takeInData: begin
                //takeInData State
                matrices_loaded = 0;
                aAddress = aCurrentAddress;
                bAddress = bCurrentAddress;

                //localA is controlled by the FSM
                if (localA == 1) begin
                    bWriteEnable = 0;
                    aWriteEnable = 1;
                end else begin
                    bWriteEnable = 1;
                    aWriteEnable = 0;
                    if (nextState == memRead) begin
                        bWriteEnable = 0;
                    end
                end
                
            end 
                memRead: begin
                //memRead state
                aWriteEnable = 0;
                bWriteEnable = 0;

                matrices_loaded = 1;
                K = localK;

                aAddress = A_read_addr;
                bAddress = B_read_addr;

                if (nextState == takeInFirst) begin
                    matrices_loaded = 0;
                end

            end
        endcase

    end

//This state machine should only handle control logic, not data logic. All data logic takes place in the above always_comb block
    always_ff @(posedge clk) begin
    //Everything in this if block should be wrapped in another if statement, which ensures TVALID is 1
    //State stuff goes here

        if (reset == 1) begin 
            currentState = takeInFirst;
            AXIS_TREADY = 1;
            aCurrentAddress = 0;
            bCurrentAddress = 0;
            localA = 1; //Assume we always have to read in matrixA first

        end else begin

        currentState = nextState;

        unique case (currentState)
                takeInFirst: begin
                    AXIS_TREADY = 1;
                    //First check if the data stream is ready and valid
                    if (AXIS_TVALID == 1) begin
                        //Update local variables
                        localA = new_A;
                        localK = TUSER_K;
                        if (new_A == 1) begin
                            //If we recieved from matrixA
                            aCurrentAddress++;
                        end else begin
                            //If we recieved from matrixB
                            bCurrentAddress++;
                        end

                        nextState = takeInData;
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

                    if (AXIS_TVALID ==1) begin 
                        if(localA == 0) begin
                            //MatrixB stuff
                            //If MatrixB is done reading, move onto the next state
                            if (bCurrentAddress == (localK * N)-1) begin
                                AXIS_TREADY = 0;
                                nextState = memRead;
                                //bWriteEnable = 0;
                            end
                            else begin
                                // bWriteEnable = 1;
                                // aWriteEnable = 0;
                                nextState = takeInData;
                                bCurrentAddress = bCurrentAddress + 1;
                            end
                        end else begin
                            //MatrixA stuff
                            nextState = takeInData;
                            //If MatrixA is done reading, move onto reading Matrix B
                            if (aCurrentAddress == (localK * M)-1) begin
                                localA = 0;
                                //aWriteEnable = 0;   //Make sure to close off aWriteEnable
                            end else begin
                                aCurrentAddress = aCurrentAddress + 1;
                                // aWriteEnable = 1;
                                // bWriteEnable = 0;
                            end
                        end
                    end

                    
                end

                memRead: begin
                    AXIS_TREADY = 0;
                    //memory read stuff goes in here first
                    //This state changes when compute_finished = 1 and moves the FSM back to waitForValid
                    if (compute_finished == 1) begin
                        nextState = takeInFirst;

                        //Reset current addressing to 0 for both a and b
                        aCurrentAddress = 0;
                        bCurrentAddress = 0;
                    end
                end 
            
            endcase
        end
    end
endmodule

