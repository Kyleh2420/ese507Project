//Kyle Han's Fresh attempt at trying to figure out this dang thing
//In this version, we've made sure to seperate out the datapath from the FSM Control path
//Hopefully this makes debugging easier and works on the first try (Fat chance lol)

//The FSM only has control over 4 things: aCurrentAddress, bCurrentAddress, currentState, localK


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

    //Logic symbols to assist in sepearting out newA and K from the line AXIS_TUSER
    logic newA;
    assign newA = AXIS_TUSER[0];
    logic [$clog2(MAXK+1)-1:0] TUSER_K;
    assign TUSER_K = AXIS_TUSER[$clog2(MAXK+1):1];


    //State logic -- uses enumerations
    enum {takeInFirst, storeA, storeB, memRead} currentState;

    //"Local Variables"
    //Storage of local variables (registers) that will need to be incremented and changed according to the state
    logic [A_ADDR_BITS-1:0] aCurrentAddress;    //Total Address Bits required by memory bank A
    logic [B_ADDR_BITS-1:0] bCurrentAddress;    //Total Address Bits required by memory bank B
    logic [K_BITS-1:0] localK;                  //Stores the value of K when recieving it for the first time.

    //Named nets between the memory modules (Just to keep things organized)
    logic[A_ADDR_BITS-1:0] aAddress;
    logic[B_ADDR_BITS-1:0] bAddress;
    logic aWriteEnable, bWriteEnable;


    //Memory instantiation for both the A and B data banks
    memory #(INW,(2**A_ADDR_BITS)) matrixA(
        .data_in(AXIS_TDATA),   //Memories get a direct connection to the input data. To control read/writes, use the writeEnable signals
        .data_out(A_data),
        .addr(aAddress),
        .clk(clk),
        .wr_en(aWriteEnable)
    );
    memory #(INW,(2**B_ADDR_BITS)) matrixB(
        .data_in(AXIS_TDATA),   //Memories get a direct connection to the input data. To control read/writes, use the writeEnable signals
        .data_out(B_data),
        .addr(bAddress),
        .clk(clk),
        .wr_en(bWriteEnable)
    );


    //Datapath begin
    always_comb begin
        //Output the stored value of K
        //Doesn't need to be valid until currentState = memRead
        K = localK;

        unique case (currentState)
                takeInFirst: begin
                    matrices_loaded = 0;    //Adjusted based on current state
                    AXIS_TREADY = 1;        //Adjusted based on current state

                    //Memory address controlled by internal logic
                    aAddress = aCurrentAddress;
                    bAddress = bCurrentAddress; 

                    //the following should only happen when the data is valid. Otherwise, do not write anything.
                    if (AXIS_TVALID == 1) begin
                        //both current addresses have already been set to 0 by the preceding case (either reset or memRead)
                        if(newA == 0) begin     //newA = 0 when reading in B (keeping A); newA = 1 when reading in A (replacing A)
                            aWriteEnable = 0;   //Do not write to A
                            bWriteEnable = 1;   //Write into B
                        end else begin
                            bWriteEnable = 0;   //Do not write to B
                            aWriteEnable = 1;   //Write into A
                        end
                    end else begin
                        aWriteEnable = 0;
                        bWriteEnable = 0;
                    end
                end

                storeA: begin
                    matrices_loaded = 0;    //Adjusted based on current state
                    AXIS_TREADY = 1;        //Adjusted based on current state

                    //Memory address controlled by internal logic
                    aAddress = aCurrentAddress;
                    bAddress = bCurrentAddress; 

                    //Copy the data into memory bank A if the data is valid
                    //Otherwise, don't copy anything
                    if (AXIS_TVALID == 1) begin
                        aWriteEnable = 1;   //Write into A
                        bWriteEnable = 0;   //Do not write into B
                    end else begin
                        aWriteEnable = 0;
                        bWriteEnable = 0;
                    end
                end

                storeB: begin
                    matrices_loaded = 0;    //Adjusted based on current state
                    AXIS_TREADY = 1;        //Adjusted based on current state

                    //Memory address controlled by internal logic
                    aAddress = aCurrentAddress;
                    bAddress = bCurrentAddress; 

                    //Copy the data into memory bank B if the data is valid
                    //Otherwise, don't copy anything
                    if (AXIS_TVALID == 1) begin
                        aWriteEnable = 0;   //Do not write into A
                        bWriteEnable = 1;   //Write into B
                    end else begin
                        aWriteEnable = 0;
                        bWriteEnable = 0;
                    end
                end

                memRead: begin
                    matrices_loaded = 1;    //Adjusted based on current state
                    AXIS_TREADY = 0;        //Adjusted based on current state

                    //Originally, I had K output here. However, this created a latch. Thus, I've moved the K outside the case
                    //K doesn't need to be valid until this point anyways, which it will be

                    //Memory bank address controlled by output logic
                    aAddress = A_read_addr;
                    bAddress = B_read_addr;

                    //Nothing gets written in this stage
                    aWriteEnable = 0;
                    bWriteEnable = 0;
                end
            endcase

    end


    //Controlpath begin
    always_ff @(posedge clk) begin
        
        //Synchronous Reset line
        if (reset == 1) begin
            currentState <= takeInFirst;
            aCurrentAddress <= 0;
            bCurrentAddress <= 0;
        end else begin

            unique case (currentState)
                takeInFirst: begin
                    //The following should only happen when AXIS_TVALID = 1
                    //If newA = 0, we're reading in B. Jump to state readB. 
                    //If newA = 1, we're reading in A. Jump to state readA. 
                    //Increment the corresponding [A/B]CurrentAddress accordingly (These were already set to 0 by a previous state)
                    if (AXIS_TVALID == 1) begin
                        if (newA == 0) begin
                            currentState <= storeB;
                            bCurrentAddress <= bCurrentAddress + 1;
                        end else begin
                            currentState <= storeA;
                            aCurrentAddress <= aCurrentAddress + 1;
                        end

                        localK <= TUSER_K;       //Take in the value of K and store it in a local register
                    end else begin
                        currentState <= takeInFirst;
                    end
                end

                storeA: begin
                    //If the data is valid, then increment the addressing. 
                    //Check if that incremented address will be the maximum address - 1. If it is
                        //If it is, next state is storeB.
                        //Otherwise, next state is storeA.
                    if (AXIS_TVALID == 1) begin
                        if (aCurrentAddress == ((M * localK)-1)) begin
                            currentState <= storeB;
                            bCurrentAddress <= 0;    //This shoud have been set previously, but for my sanity, let's set this to 0
                        end else begin
                            aCurrentAddress <= aCurrentAddress + 1;
                            currentState <= storeA;
                        end
                    end else begin
                        currentState <= storeA;
                    end
                end

                storeB: begin

                    //If the data is valid, then increment the addressing. 
                    //Check if that incremented address will be the maximum address - 1. If it is
                        //If it is, next state is memRead.
                        //Otherwise, next state is storeB.
                    if (AXIS_TVALID == 1) begin
                        if (bCurrentAddress == ((N * localK)-1)) begin
                            currentState <= memRead;
                        end else begin
                            bCurrentAddress <= bCurrentAddress + 1;
                            currentState <= storeB;
                        end
                    end else begin
                        currentState <= storeB;
                    end

                end

                memRead: begin
                    //If the compute is finished, go back to reading in the numbers
                    if (compute_finished == 0) begin
                        currentState <= memRead;
                    end else begin
                        currentState <= takeInFirst;
                        aCurrentAddress <= 0;
                        bCurrentAddress <= 0;
                    end
                end
            endcase
        end
    end

endmodule