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
	
	logic [2*INW-1:0] product;		
	logic [OUTW-1:0] sum;

	//Multiply two values
	always_comb begin
		
		product = in0*in1;
		
	end

	//Add register sum and product
	always_comb begin
		
		//Saturation detection
		//If sum of two positives get a negative
		if ((product > 0) && (out > 0) && ((out + product) < 0)) begin
			sum = MAXVAL;
		end
		//If sum of two negatives get a positive
		else if((product < 0) && (out < 0) && ((out + product) > 0)) begin
			sum = MINVAL;
		end
		//If addition goes well
		else begin
			sum = product + out;
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
