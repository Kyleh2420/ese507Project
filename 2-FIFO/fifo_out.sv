module memory_dual_port #(
		parameter WIDTH=16, SIZE=64,
		localparam LOGSIZE=$clog2(SIZE)
	)(
		input [WIDTH-1:0] data_in,
		output logic [WIDTH-1:0] data_out,
		input [LOGSIZE-1:0] write_addr, read_addr,
		input clk, wr_en
	);
	logic [SIZE-1:0][WIDTH-1:0] mem;
	
	always_ff @(posedge clk) begin
		data_out <= mem[read_addr];
		if (wr_en) begin
			mem[write_addr] <= data_in;
			if (read_addr == write_addr)
				data_out <= data_in;
		end
	end
endmodule

module fifo_out #(
		parameter OUTW = 48,
		parameter DEPTH = 17,
		localparam LOGDEPTH = $clog2(DEPTH)
	)(
		input clk,
		input reset,
		input [OUTW-1:0] data_in,
		input wr_en,
		output logic [$clog2(DEPTH+1)-1:0] capacity,
		output logic [OUTW-1:0] AXIS_TDATA,
		output logic AXIS_TVALID,
		input AXIS_TREADY
	);

	//Variable instantiation
	logic [LOGDEPTH-1:0] wr_addr,rd_addr,tail;

	//Head Logic
	always_ff @(posedge clk) begin
		//If not reset
		if (reset == 0) begin
			//If wr_en is on
			if ((wr_en == 1) && (capacity > 0))
				//Check if head is at the end (Depth might not be a power of 2)
				wr_addr <= (wr_addr == DEPTH-1) ? 0 : wr_addr + 1;
		end
		else begin
			wr_addr <= 0;
		end
	end
	
	//Read Address Logic combinational block
	always_comb begin
		if (AXIS_TREADY && AXIS_TVALID) begin
			//If tail is pointing to the last word, then roll over. Otherwise, increment
			rd_addr = (tail == DEPTH-1) ? 0 : tail + 1;
		end
		else begin
			rd_addr = tail;
		end
	end
	
	//Tail Logic
	always_ff @(posedge clk) begin
		//If not reset
		if (reset == 0) begin
			//If rd_en is on
			if (AXIS_TREADY && AXIS_TVALID)
				//Check if tail is at the end (Depth might not be a power of 2)
				tail <= (tail == DEPTH-1) ? 0 : tail + 1;
		end
		else begin
			tail <= 0;
		end
	end

	//TVALID Logic
	always_comb begin
		//If there's somehing in the FIFO, it is valid
		AXIS_TVALID = (capacity < DEPTH) ? 1 : 0;
	end

	//Capacity Logic
	always_ff @(posedge clk) begin
		if (reset == 1) begin
			capacity <= DEPTH;
		end
		else begin
			//Redundant but takes care of the situations when wr_en and rd_en are equal for the other if statements
			if ((AXIS_TREADY == wr_en) && AXIS_TVALID) begin
				capacity <= capacity;	
			end
			//Decrement capacity if we're writing
			else if ((wr_en == 1) && (capacity > 0)) begin
				capacity  <= capacity - 1;
			end
			//Increment capacity if reading
			else if ((AXIS_TREADY == 1) && AXIS_TVALID) begin
				capacity <= capacity + 1;
			end
		end
	end

	//Mem Instantiation
	memory_dual_port #(OUTW,DEPTH) myMemInst(
		.clk(clk),
		.data_in(data_in),
		.data_out(AXIS_TDATA),
		.write_addr(wr_addr),
		.read_addr(rd_addr),
		.wr_en(wr_en)
	);
endmodule
