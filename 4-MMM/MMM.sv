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
    logic fifoWrite;
    logic [$clog2(DEPTH+1)-1:0] fifoCapacity;



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
        .wr_en(fifoWrite),
        .capacity(),
        .AXIS_TDATA(OUTPUT_TDATA),
        .AXIS_TVALID(OUTPUT_TVALID),
        .AXIS_TREADY(OUTPUT_TREADY)
    );

endmodule