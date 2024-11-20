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

    input_mems #(INW, M, N, MAXK) inputMem(
        .clk(clk),
        .reset(reset),
        .AXIS_TDATA(INPUT_TDATA)
        .AXIS_TVALID(INPUT_TVALID),
        .AXIS_TUSER(INPUT_TUSER),
        .AXIS_TREADY(INPUT_TREADY),
        .matrices_loaded(),
        .compute_finished(),
        .K(),
        .A_read_addr(),
        .A_data(),
        .B_read_addr(),
        .B_data()
    );

    mac_pipe #(INW, OUTW) mac(
        .in0(), 
        .in1(),
        .out(),
        .clk(clk), 
        .reset(reset), 
        .clear_acc(),
        .valid_input()
    );

    fifo_out #(OUTW, N) fifo(
        .clk(clk),
        .reset(reset),
        .data_in(),
        .wr_en(),
        .capacity(),
        .AXIS_TDATA(OUTPUT_TDATA),
        .AXIS_TVALID(OUTPUT_TVALID),
        .AXIS_TREADY(OUTPUT_TREADY)
    );

endmodule