module mac_pipe #(
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
    logic signed [2*INW-1:0] add1;	

	// //Multiply two values
	// always_comb begin
	// 	product = in0*in1;
	// end

	DW02_mult_2_stage #(INW, INW) multinstance(in0, in1, 1'b1, clk, product);

	// DW02_mult_3_stage #(INW, INW) multinstance(in0, in1, 1'b1, clk, product);

	// DW02_mult_6_stage #(INW, INW) multinstance(in0, in1, 1'b1, clk, product);

    always_ff @ (posedge clk) begin
        //If valid_input_delay1 = 1, then we can accept the multiplication. Otherwise, output 0.
        if (valid_input == 1) begin
            add1 <= product;
        end
        else begin
            add1 <= 0;
        end
    end

	//Add register sum and product
	always_comb begin
		//Here I'm trying something
		if (clear_acc == 1) begin
			sum = add1;
		end else begin
			sum = out + add1;
		end

		//Complete the saturation detection here.
		//If the signs of the two input match, we may have overflowed. 
		//Further check if the sign has flipped in the sum. If the sign has flipped, then we have overflowed.
		if ((out[OUTW-1] == add1[2*INW-1]) && (sum[OUTW-1] != out[OUTW-1])) begin
			//Check which way we have overflowed
			if (sum[OUTW-1] == 1) sum = MAXVAL;
			else sum = MINVAL;
		end
	end

	//Register
	always_ff @ (posedge clk) begin

		//If there is a reset or clear, set the output to 0
		if ((reset == 1)) begin
			out <= 0;
		end
		else begin
			out <= sum;
		end
	end
endmodule
