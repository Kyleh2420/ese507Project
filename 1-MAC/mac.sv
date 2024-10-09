module mac #(
	parameter INW = 16;
	parameter OUTW = 48;
	localparam MINVAL = ((64'd1<<(OUTW-1)),
	localparam MAXVAL = (64'd1<<(OUTW-1))-1
)(
	input signed [INW-1:0] in0, in1,
	output logic signed [OUTW-1:0] out,
	input clk, reset, clear_acc, valid_input
);
