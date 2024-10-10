module mac #(
	parameter INW = 16,
	parameter OUTW = 48,
	localparam MINVAL = (64'd1<<(OUTW-1)),
	localparam MAXVAL = (64'd1<<(OUTW-1))-1
)(
	input signed [INW-1:0] in0, in1,
	output logic signed [OUTW-1:0] out,
	input clk, reset, clear_acc, valid_input
);
	
	logic signed [2*INW-1:0] product;		
	logic signed [OUTW-1:0] sum;

	//Multiply two values
	always_comb begin
		
		product = in0*in1;
		
	end

	//Add register sum and product
	always_comb begin
		
		sum = out + product;

		//Complete the saturation detection here.
		//If the signs of the two input match, we may have overflowed. 
		//Further check if the sign has flipped in the sum. If the sign has flipped, then we have overflowed.
		if ((out[OUTW-1] == product[2*INW-1]) && (sum[OUTW-1] != out[OUTW-1])) begin
			//Check which way we have overflowed
			if (sum[OUTW-1] == 1) sum = MAXVAL;
			else sum = MINVAL;
		end
	end

	//Register
	always_ff @ (posedge clk) begin

		//If there is a reset or clear, set the output to 0
		if ((clear_acc == 1) || (reset == 1)) begin
			out <= 0;
		end
		else begin
			//If the input is valid, then send the saturated sum to the output
			if (valid_input == 1) out <= sum;
			else out <= out; //Required to remove the implied latch
		end
	end
endmodule
