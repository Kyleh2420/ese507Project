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
	logic [OUTW-1:0] feedback;

	//Multiply two values
	always_comb begin
		
		product = in0*in1;
		
	end

	//Add register feedback and product
	always_comb begin
		
		//Saturation detection
		//If sum of two positives get a negative
		if ((in1 > 0) && (in0 > 0) && ((in0 + in1) < 0)) begin

			sum = MAXVAL;

		end
		//If sum of two negatives get a positive
		else if((in1 < 0) && (in0 < 0) && ((in0 + in1) > 0)) begin

			sum = MINVAL;

		end
		//If addition goes well
		else begin

			sum = product + feedback;
			
		end

	end

	//Register
	always_ff @ (posedge clk) begin

		//As long as we don't get a clear or reset
		if ((clear_acc == 0) || (reset == 0)) begin

			//Need a valid input to copy onto out
			if (valid_input == 1) begin

				out <= sum;
				feedback <= sum;

			end
		end
		//If we get a reset or clear
		else begin

			out <= 0;
			feedback <= 0;

		end
	
	end

endmodule
