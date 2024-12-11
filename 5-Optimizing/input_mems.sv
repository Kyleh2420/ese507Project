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


module input_mems_interface #(
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
        output logic signed [INW-1:0] B_data,
        output logic newAOut
    );

    //Logic symbols to assist in sepearting out newA and K from the line AXIS_TUSER
    logic newA;
    assign newA = AXIS_TUSER[0];
    logic [$clog2(MAXK+1)-1:0] TUSER_K;
    assign TUSER_K = AXIS_TUSER[$clog2(MAXK+1):1];


    //State logic -- uses enumerations
    enum {takeInFirst, storeA, storeB, memRead} currentState, nextState;

    //"Local Variables"
    //Storage of local variables (registers) that will need to be incremented and changed according to the state
    logic [A_ADDR_BITS-1:0] aCurrentAddress;    //Total Address Bits required by memory bank A
    logic [B_ADDR_BITS-1:0] bCurrentAddress;    //Total Address Bits required by memory bank B
    logic [K_BITS-1:0] localK;                  //Stores the value of K when recieving it for the first time.
    logic localA;                               //Stores the value of A for the next state in the pipeline

    //Named nets between the memory modules (Just to keep things organized)
    logic[A_ADDR_BITS-1:0] aAddress;
    logic[B_ADDR_BITS-1:0] bAddress;
    logic aWriteEnable, bWriteEnable;


    //Memory instantiation for both the A and B data banks
    memory #(INW,M*MAXK) matrixA(
        .data_in(AXIS_TDATA),   //Memories get a direct connection to the input data. To control read/writes, use the writeEnable signals
        .data_out(A_data),
        .addr(aAddress),
        .clk(clk),
        .wr_en(aWriteEnable)
    );
    memory #(INW,MAXK*N) matrixB(
        .data_in(AXIS_TDATA),   //Memories get a direct connection to the input data. To control read/writes, use the writeEnable signals
        .data_out(B_data),
        .addr(bAddress),
        .clk(clk),
        .wr_en(bWriteEnable)
    );

    
    //nextState logic
    always_comb begin
        unique case (currentState)
            takeInFirst: begin
                //The following should only happen when AXIS_TVALID = 1
                //If newA = 0, we're reading in B. Jump to state readB. 
                //If newA = 1, we're reading in A. Jump to state readA. 
                //Increment the corresponding [A/B]CurrentAddress accordingly (These were already set to 0 by a previous state)
                if (AXIS_TVALID == 1) begin
                    if (newA == 0) begin
                        nextState = storeB;
                    end else begin
                        nextState = storeA;
                    end
                end else begin
                    nextState = takeInFirst;
                end
            end
            storeA: begin
                //If the data is valid, then increment the addressing. 
                //Check if that incremented address will be the maximum address - 1. If it is
                    //If it is, next state is storeB.
                    //Otherwise, next state is storeA.
                if (AXIS_TVALID == 1) begin
                        if (aCurrentAddress == ((M * localK)-1)) begin
                            nextState = storeB;
                        end else begin
                            nextState = storeA;
                        end
                    end else begin
                        nextState = storeA;
                    end
            end
            storeB: begin
                //If the data is valid, then increment the addressing. 
                //Check if that incremented address will be the maximum address - 1. If it is
                    //If it is, next state is memRead.
                    //Otherwise, next state is storeB.
                if (AXIS_TVALID == 1) begin
                    if (bCurrentAddress == ((N * localK)-1)) begin
                        nextState = memRead;
                    end else begin
                        nextState = storeB;
                    end
                end else begin
                    nextState = storeB;
                end
            end
            memRead: begin
                //If the compute is finished, go back to reading in the numbers
                if (compute_finished == 0) begin
                    nextState = memRead;
                end else begin
                    nextState = takeInFirst;
                end
            end
        endcase
    end

    //Datapath begin
    always_comb begin
        //Output the stored value of K
        //Doesn't need to be valid until currentState = memRead
        K = localK;
        newAOut = localA;

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
        currentState <= nextState;
        
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
                            bCurrentAddress <= bCurrentAddress + 1;
                        end else begin
                            aCurrentAddress <= aCurrentAddress + 1;
                        end
                        localK <= TUSER_K;       //Take in the value of K and store it in a local register
                        localA <= newA;
                    end
                end

                storeA: begin
                    //If the data is valid, then increment the addressing. 
                    //Check if that incremented address will be the maximum address - 1. If it is
                        //If it is, next state is storeB.
                        //Otherwise, next state is storeA.
                    if (AXIS_TVALID == 1) begin
                        if (aCurrentAddress == ((M * localK)-1)) begin
                            bCurrentAddress <= 0;    //This shoud have been set previously, but for my sanity, let's set this to 0
                        end else begin
                            aCurrentAddress <= aCurrentAddress + 1;
                        end
                    end
                end

                storeB: begin

                    //If the data is valid, then increment the addressing. 
                    //Check if that incremented address will be the maximum address - 1. If it is
                        //If it is, next state is memRead.
                        //Otherwise, next state is storeB.
                    if (AXIS_TVALID == 1) begin
                        if (bCurrentAddress == ((N * localK)-1)) begin
                        end else begin
                            bCurrentAddress <= bCurrentAddress + 1;
                        end
                    
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

module input_mems_computation #(
        parameter INW = 12,
        parameter M = 7,
        parameter N = 9,
        parameter MAXK = 8,
        localparam K_BITS = $clog2(MAXK+1),
        localparam A_ADDR_BITS = $clog2(M*MAXK),
        localparam B_ADDR_BITS = $clog2(MAXK*N)
    )(
        input clk, reset,

        input logic [INW-1:0] A_data_in,
        output logic [A_ADDR_BITS-1:0] A_addr_in,

        input logic [INW-1:0] B_data_in,
        output logic [B_ADDR_BITS-1:0] B_addr_in,

        input logic finishedLoading,

        output logic getNewData,

        input logic [K_BITS-1:0] K_in,
        input logic newAIn,

        input [A_ADDR_BITS-1:0] A_read_addr,
        input [B_ADDR_BITS-1:0] B_read_addr,
        output logic signed [INW-1:0] B_data,
        output logic signed [INW-1:0] A_data,

        output logic matrices_loaded,
        input compute_finished,

        output logic [K_BITS-1:0] K
        
    );

    //State logic -- uses enumerations
    enum {storeA, storeB, memRead, waitForLoad} currentState, nextState;


    //"Local Variables"
    //Storage of local variables (registers) that will need to be incremented and changed according to the state
    logic [A_ADDR_BITS-1:0] aCurrentAddress;    //Total Address Bits required by memory bank A
    logic [B_ADDR_BITS-1:0] bCurrentAddress;    //Total Address Bits required by memory bank B

    logic [A_ADDR_BITS-1:0] aCurrentAddress_delay1;    //Total Address Bits required by memory bank A
    logic [B_ADDR_BITS-1:0] bCurrentAddress_delay1;    //Total Address Bits required by memory bank B

    //Named nets between the memory modules (Just to keep things organized)
    logic[A_ADDR_BITS-1:0] aAddress;
    logic[B_ADDR_BITS-1:0] bAddress;
    logic aWriteEnable, bWriteEnable;

    logic [K_BITS-1:0] localK;  

    //Memory instantiation for both the A and B data banks
    memory #(INW,M*MAXK) matrixA(
        .data_in(A_data_in),   //Memories get a direct connection to the input data. To control read/writes, use the writeEnable signals
        .data_out(A_data),
        .addr(aAddress),
        .clk(clk),
        .wr_en(aWriteEnable)
    );
    memory #(INW,MAXK*N) matrixB(
        .data_in(B_data_in),   //Memories get a direct connection to the input data. To control read/writes, use the writeEnable signals
        .data_out(B_data),
        .addr(bAddress),
        .clk(clk),
        .wr_en(bWriteEnable)
    );
    

    //Logic for write enables and addressing multiplexing
    //Also takes care of matrices Loaded signal
    always_comb begin
        //K only needs to be correct when we enter memRead.
        K = localK;
        A_addr_in = aCurrentAddress;
        B_addr_in = bCurrentAddress;

        case (currentState)
            storeA: begin
                matrices_loaded = 0;
                aAddress = aCurrentAddress_delay1;
                bAddress = bCurrentAddress_delay1;

                aWriteEnable = 1;
                bWriteEnable = 0;
            end
            storeB: begin
                matrices_loaded = 0;
                aAddress = aCurrentAddress_delay1;
                bAddress = bCurrentAddress_delay1;

                aWriteEnable = 0;
                bWriteEnable = 1;
            end
            memRead: begin
                matrices_loaded = 1;
                aAddress = A_read_addr;
                bAddress = B_read_addr;

                aWriteEnable = 0;
                bWriteEnable = 0;
            end
            waitForLoad: begin
                matrices_loaded = 0;
                aAddress = A_read_addr;
                bAddress = B_read_addr;

                aWriteEnable = 0;
                bWriteEnable = 0;
            end
            default: begin
                //Used to elimnate latches
                matrices_loaded = 0;
                aAddress = A_read_addr;
                bAddress = B_read_addr;

                aWriteEnable = 0;
                bWriteEnable = 0;
            end
        endcase
    end

    //Incrementing logic/current state stuff
    //Increments the current address of the corresponding value on clock edge.
    //Otherwise, sets it to 0 for the other values
    always_ff @( posedge clk ) begin

        aCurrentAddress_delay1 <= aCurrentAddress;
        bCurrentAddress_delay1 <= bCurrentAddress;

        //Synchronous reset line
        if (reset == 1) begin
            currentState <= waitForLoad;
            aCurrentAddress <= 0;
            bCurrentAddress <= 0;
        end else begin
            currentState <= nextState;
        end

        case (currentState)
            storeA: begin
                aCurrentAddress <= aCurrentAddress + 1;
            end
            storeB: begin
                bCurrentAddress <= bCurrentAddress + 1;
            end
            memRead: begin
                aCurrentAddress <= 0;
                bCurrentAddress <= 0;
            end
            waitForLoad: begin
                aCurrentAddress <= 0;
                bCurrentAddress <= 0;
            end
        endcase
    end

    //Takes care of nextState logic
    always_comb begin
        case (currentState)
            storeA: begin
                getNewData = 0;
                if (aCurrentAddress == ((M * K_in))) begin
                    nextState = storeB;
                end else begin
                    nextState = storeA;
                end
            end
            storeB: begin
                getNewData = 0;
                if (bCurrentAddress == ((N * K_in))) begin
                    getNewData = 1; //Trigger the other input_mems module to get new data from the AXIS interface in preparation for the next read
                    nextState = memRead;
                end else begin
                    nextState = storeB;
                end
            end
            memRead: begin
                getNewData = 0;
                if (compute_finished == 1) begin
                    if (finishedLoading == 1) begin
                        //As long as the previous stage is done loading, we should change state
                        if (newAIn == 1) begin
                            //If we should rewrite A, go here
                            nextState = storeA;
                            localK = K_in;  //Copy the new K into the local memory
                        end else begin
                            //If we should just rewrite B, go here
                            nextState = storeB;
                            localK = K_in;  //Copy the new K into the local memory
                        end
                    end else begin
                        //If the previous stge is not done loading, just wait for it complete loading
                        nextState = waitForLoad;
                    end
                end else begin
                    nextState = memRead;
                end
            end
            waitForLoad: begin
                getNewData = 0;
                if (finishedLoading == 1) begin
                        //As long as the previous stage is done loading, we should change state
                        if (newAIn == 1) begin
                            //If we should rewrite A, go here
                            nextState = storeA;
                            localK = K_in;  //Copy the new K into the local memory
                        end else begin
                            //If we should just rewrite B, go here
                            nextState = storeB;
                            localK = K_in;  //Copy the new K into the local memory
                        end
                    end else begin
                        //If the previous stge is not done loading, just wait for it complete loading
                        nextState = waitForLoad;
                    end
            end
            default: begin
                getNewData = 0;
                nextState = waitForLoad;

            end
        endcase
    end

endmodule

module input_mems_buffer #(
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

    //Linkages between interface and computation sections of input_mems
    logic matricesLoaded, computeFinished, newA;
    logic [K_BITS-1:0] K_in;
    logic [$clog2(M*MAXK)-1:0] aAddress;
    logic [$clog2(MAXK*N)-1:0] bAddress;
    logic signed [INW-1:0] aData, bData;


    //Instantiation for the interface portion of input_mems
    input_mems_interface #(INW, M, N, MAXK) input_interface(
        .clk(clk),
        .reset(reset),
        .AXIS_TDATA(AXIS_TDATA),
        .AXIS_TVALID(AXIS_TVALID),
        .AXIS_TUSER(AXIS_TUSER),
        .AXIS_TREADY(AXIS_TREADY),
        .matrices_loaded(matricesLoaded),
        .compute_finished(computeFinished),
        .K(K_in),
        .A_read_addr(aAddress),
        .A_data(aData),
        .B_read_addr(bAddress),
        .B_data(bData),
        .newAOut(newA)
    );


    //Instantiation for the computation portion of input_mems
    input_mems_computation #(INW, M, N, MAXK) input_computation(
        .clk(clk),
        .reset(reset),
        .A_data_in(aData),
        .A_addr_in(aAddress),
        .B_data_in(bData),
        .B_addr_in(bAddress),
        .finishedLoading(matricesLoaded),
        .getNewData(computeFinished),
        .K_in(K_in),
        .newAIn(newA),
        .A_read_addr(A_read_addr),
        .B_read_addr(B_read_addr),
        .A_data(A_data),
        .B_data(B_data),
        .matrices_loaded(matrices_loaded),
        .compute_finished(compute_finished),
        .K(K)
    );

endmodule

module input_mems_computation2x #(
        parameter INW = 12,
        parameter M = 7,
        parameter N = 9,
        parameter MAXK = 8,
        localparam K_BITS = $clog2(MAXK+1),
        localparam A_ADDR_BITS = $clog2(M*MAXK),
        localparam B_ADDR_BITS = $clog2(MAXK*N)
    )(
        input clk, reset,

        input logic [INW-1:0] A_data_in,
        output logic [A_ADDR_BITS-1:0] A_addr_in,

        input logic [INW-1:0] B_data_in,
        output logic [B_ADDR_BITS-1:0] B_addr_in,

        input logic finishedLoading,

        output logic getNewData,

        input logic [K_BITS-1:0] K_in,
        input logic newAIn,

        input [A_ADDR_BITS-1:0] A_read_addr,
        input [B_ADDR_BITS-1:0] B_read_addr,
        output logic signed [INW-1:0] B_data,
        output logic signed [INW-1:0] A_data,

        output logic matrices_loaded,
        input compute_finished,

        output logic [K_BITS-1:0] K
        
    );

    //State logic -- uses enumerations
    enum {storeMatrix, memRead, waitForLoad} currentState, nextState;


    //"Local Variables"
    //Storage of local variables (registers) that will need to be incremented and changed according to the state
    logic [A_ADDR_BITS-1:0] aCurrentAddress;    //Total Address Bits required by memory bank A
    logic [B_ADDR_BITS-1:0] bCurrentAddress;    //Total Address Bits required by memory bank B

    logic [A_ADDR_BITS-1:0] aCurrentAddress_delay1;    //Total Address Bits required by memory bank A
    logic [B_ADDR_BITS-1:0] bCurrentAddress_delay1;    //Total Address Bits required by memory bank B

    //Named nets between the memory modules (Just to keep things organized)
    logic[A_ADDR_BITS-1:0] aAddress;
    logic[B_ADDR_BITS-1:0] bAddress;
    logic aWriteEnable, bWriteEnable;

    logic [K_BITS-1:0] localK;  

    //Memory instantiation for both the A and B data banks
    memory #(INW,M*MAXK) matrixA(
        .data_in(A_data_in),   //Memories get a direct connection to the input data. To control read/writes, use the writeEnable signals
        .data_out(A_data),
        .addr(aAddress),
        .clk(clk),
        .wr_en(aWriteEnable)
    );
    memory #(INW,MAXK*N) matrixB(
        .data_in(B_data_in),   //Memories get a direct connection to the input data. To control read/writes, use the writeEnable signals
        .data_out(B_data),
        .addr(bAddress),
        .clk(clk),
        .wr_en(bWriteEnable)
    );
    

    //Logic for write enables and addressing multiplexing
    //Also takes care of matrices Loaded signal
    always_comb begin
        //K only needs to be correct when we enter memRead.
        K = localK;
        A_addr_in = aCurrentAddress;
        B_addr_in = bCurrentAddress;

        case (currentState)
            storeMatrix: begin
                matrices_loaded = 0;
                aAddress = aCurrentAddress_delay1;
                bAddress = bCurrentAddress_delay1;

                //Default values
                aWriteEnable = 0;
                bWriteEnable = 0;
                //As long as we are still below the maximum, continue leaving wrEn = 1
                if (aCurrentAddress <= ((M * K_in))) begin
                    aWriteEnable = 1;
                end
                //As long as we are still below the maximum, continue leaving wrEn = 1
                if (bCurrentAddress <= ((N * K_in))) begin
                    bWriteEnable = 1;
                end
            end
            memRead: begin
                matrices_loaded = 1;
                aAddress = A_read_addr;
                bAddress = B_read_addr;

                aWriteEnable = 0;
                bWriteEnable = 0;
            end
            default: begin
                matrices_loaded = 0;
                aAddress = A_read_addr;
                bAddress = B_read_addr;

                aWriteEnable = 0;
                bWriteEnable = 0;
            end
        endcase
    end

    //Incrementing logic/current state stuff
    //Increments the current address of the corresponding value on clock edge.
    //Otherwise, sets it to 0 for the other values
    always_ff @( posedge clk ) begin

        aCurrentAddress_delay1 <= aCurrentAddress;
        bCurrentAddress_delay1 <= bCurrentAddress;

        //Synchronous reset line
        if (reset == 1) begin
            currentState <= waitForLoad;
            aCurrentAddress <= 0;
            bCurrentAddress <= 0;
        end else begin
            currentState <= nextState;
        end

        case (currentState)
            storeMatrix: begin
                //As long as we are still below the maximum, continue incrementing
                if (aCurrentAddress <= ((M * K_in))) begin
                    aCurrentAddress <= aCurrentAddress + 1;
                end
                //As long as we are still below the maximum, continue incrementing
                if (bCurrentAddress <= ((N * K_in))) begin
                    bCurrentAddress <= bCurrentAddress + 1;
                end
            end
            default: begin
                aCurrentAddress <= 0;
                bCurrentAddress <= 0;
                if (nextState == storeMatrix) begin
                    localK = K_in;  //Copy the new K into the local memory
                    //If we're about to go back into storeMatrix, check if newAIn = 1. If it is 0, then skip reading A
                    if (newAIn == 0) begin
                        //Set A to the maximum so we never trigger the incrementing/wr_en
                        aCurrentAddress <= (M * K_in);
                    end
                end
            end
        endcase
    end

    //Takes care of nextState logic
    always_comb begin
        case (currentState)

            storeMatrix: begin
                //If we are done filling up both matrices, move onto memRead
                if ((aCurrentAddress >= ((M * K_in))) && (bCurrentAddress >= ((N * K_in)))) begin
                    nextState = memRead;
                    getNewData = 1; //Trigger the other input_mems module to get new data from the AXIS interface in preparation for the next read
                end else begin
                    //Otherwise, continue filling up
                    nextState = storeMatrix;
                    getNewData = 0;
                end

            end

            memRead: begin
                getNewData = 0;
                if (compute_finished == 1) begin
                    if (finishedLoading == 1) begin
                        //As long as the previous stage is done loading, we should change state
                        nextState = storeMatrix;
                    end else begin
                        //If the previous stge is not done loading, just wait for it complete loading
                        nextState = waitForLoad;
                    end
                end else begin
                    nextState = memRead;
                end
            end
            default: begin
                getNewData = 0;
                if (finishedLoading == 1) begin
                        //As long as the previous stage is done loading, we should change state
                        nextState = storeMatrix;    
                    end else begin
                        //If the previous stge is not done loading, just wait for it complete loading
                        nextState = waitForLoad;
                    end
            end
        endcase
    end

endmodule

module input_mems_buffer2x #(
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

    //Linkages between interface and computation sections of input_mems
    logic matricesLoaded, computeFinished, newA;
    logic [K_BITS-1:0] K_in;
    logic [$clog2(M*MAXK)-1:0] aAddress;
    logic [$clog2(MAXK*N)-1:0] bAddress;
    logic signed [INW-1:0] aData, bData;


    //Instantiation for the interface portion of input_mems
    input_mems_interface #(INW, M, N, MAXK) input_interface(
        .clk(clk),
        .reset(reset),
        .AXIS_TDATA(AXIS_TDATA),
        .AXIS_TVALID(AXIS_TVALID),
        .AXIS_TUSER(AXIS_TUSER),
        .AXIS_TREADY(AXIS_TREADY),
        .matrices_loaded(matricesLoaded),
        .compute_finished(computeFinished),
        .K(K_in),
        .A_read_addr(aAddress),
        .A_data(aData),
        .B_read_addr(bAddress),
        .B_data(bData),
        .newAOut(newA)
    );


    //Instantiation for the computation portion of input_mems
    input_mems_computation2x #(INW, M, N, MAXK) input_computation(
        .clk(clk),
        .reset(reset),
        .A_data_in(aData),
        .A_addr_in(aAddress),
        .B_data_in(bData),
        .B_addr_in(bAddress),
        .finishedLoading(matricesLoaded),
        .getNewData(computeFinished),
        .K_in(K_in),
        .newAIn(newA),
        .A_read_addr(A_read_addr),
        .B_read_addr(B_read_addr),
        .A_data(A_data),
        .B_data(B_data),
        .matrices_loaded(matrices_loaded),
        .compute_finished(compute_finished),
        .K(K)
    );

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
    enum {takeInFirst, storeA, storeB, memRead} currentState, nextState;

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
    memory #(INW,M*MAXK) matrixA(
        .data_in(AXIS_TDATA),   //Memories get a direct connection to the input data. To control read/writes, use the writeEnable signals
        .data_out(A_data),
        .addr(aAddress),
        .clk(clk),
        .wr_en(aWriteEnable)
    );
    memory #(INW,MAXK*N) matrixB(
        .data_in(AXIS_TDATA),   //Memories get a direct connection to the input data. To control read/writes, use the writeEnable signals
        .data_out(B_data),
        .addr(bAddress),
        .clk(clk),
        .wr_en(bWriteEnable)
    );

    
    //nextState logic
    always_comb begin
        unique case (currentState)
            takeInFirst: begin
                //The following should only happen when AXIS_TVALID = 1
                //If newA = 0, we're reading in B. Jump to state readB. 
                //If newA = 1, we're reading in A. Jump to state readA. 
                //Increment the corresponding [A/B]CurrentAddress accordingly (These were already set to 0 by a previous state)
                if (AXIS_TVALID == 1) begin
                    if (newA == 0) begin
                        nextState = storeB;
                    end else begin
                        nextState = storeA;
                    end
                end else begin
                    nextState = takeInFirst;
                end
            end
            storeA: begin
                //If the data is valid, then increment the addressing. 
                //Check if that incremented address will be the maximum address - 1. If it is
                    //If it is, next state is storeB.
                    //Otherwise, next state is storeA.
                if (AXIS_TVALID == 1) begin
                        if (aCurrentAddress == ((M * localK)-1)) begin
                            nextState = storeB;
                        end else begin
                            nextState = storeA;
                        end
                    end else begin
                        nextState = storeA;
                    end
            end
            storeB: begin
                //If the data is valid, then increment the addressing. 
                //Check if that incremented address will be the maximum address - 1. If it is
                    //If it is, next state is memRead.
                    //Otherwise, next state is storeB.
                if (AXIS_TVALID == 1) begin
                    if (bCurrentAddress == ((N * localK)-1)) begin
                        nextState = memRead;
                    end else begin
                        nextState = storeB;
                    end
                end else begin
                    nextState = storeB;
                end
            end
            memRead: begin
                //If the compute is finished, go back to reading in the numbers
                if (compute_finished == 0) begin
                    nextState = memRead;
                end else begin
                    nextState = takeInFirst;
                end
            end
        endcase
    end

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
        currentState <= nextState;
        
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
                            bCurrentAddress <= bCurrentAddress + 1;
                        end else begin
                            aCurrentAddress <= aCurrentAddress + 1;
                        end
                        localK <= TUSER_K;       //Take in the value of K and store it in a local register
                    end
                end

                storeA: begin
                    //If the data is valid, then increment the addressing. 
                    //Check if that incremented address will be the maximum address - 1. If it is
                        //If it is, next state is storeB.
                        //Otherwise, next state is storeA.
                    if (AXIS_TVALID == 1) begin
                        if (aCurrentAddress == ((M * localK)-1)) begin
                            bCurrentAddress <= 0;    //This shoud have been set previously, but for my sanity, let's set this to 0
                        end else begin
                            aCurrentAddress <= aCurrentAddress + 1;
                        end
                    end
                end

                storeB: begin

                    //If the data is valid, then increment the addressing. 
                    //Check if that incremented address will be the maximum address - 1. If it is
                        //If it is, next state is memRead.
                        //Otherwise, next state is storeB.
                    if (AXIS_TVALID == 1) begin
                        if (bCurrentAddress == ((N * localK)-1)) begin
                        end else begin
                            bCurrentAddress <= bCurrentAddress + 1;
                        end
                    
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