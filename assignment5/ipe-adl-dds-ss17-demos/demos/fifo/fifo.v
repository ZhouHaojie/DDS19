module fifo #(parameter DWIDTH=16, parameter AWIDTH=8) (

	input wire clk,
	input wire res_n,

	input wire shiftin,
	input wire [DWIDTH-1:0] data_in,

	input wire shiftout,
	output reg [DWIDTH-1:0] data_out,

	output reg full,
	output reg almost_full,
	output reg empty,
	output reg almost_empty


);

	localparam DEPTH = 2 ** AWIDTH;

	// Signals
	//------------------

	wire reading = shiftout && !empty;
	wire writing = shiftin && !full;

	// Memory && pointers
	//-----------
	reg [DWIDTH-1:0] memory [DEPTH-1:0];
	reg [AWIDTH-1:0] write_pointer;
	reg [AWIDTH-1:0] read_pointer;
	wire [AWIDTH-1:0] read_pointer_next =  read_pointer+1;

	always @(posedge clk or negedge res_n) begin
		if (!res_n) begin
			// reset
			full <= 0;
			almost_full <= 0;
			empty <= 1;
			almost_empty <= 1;
			data_out <= {DWIDTH{1'b0}};
			write_pointer <= {AWIDTH{1'b0}};
			read_pointer <= {AWIDTH{1'b0}};
		end
		else  begin
			
			// Read
			//-------
			if (writing && empty) begin
				data_out <= data_in;
			end
			// This case is when writing and reading at the same time, with one data block written
			// It means reading should go back to empty, but we are writing, so the output should be the input and staying there
			// This condition is used to 'mask' the write/read delay in this corner casse
			// Cleary it has a logic costs impacting the speed of the FIFO, but it makes the design easier
			else if (writing && reading && almost_empty) begin
				data_out <= data_in;
				read_pointer <= read_pointer+1;
			end
			else if (reading) begin
				data_out <= memory[read_pointer_next] ;
				read_pointer <= read_pointer+1;
			end

			// Write
			//--------
			if (writing) begin
				memory[write_pointer] <= data_in;
				write_pointer <= write_pointer+1;
			end

			// Full
			//---------
			if (writing && !reading &&  write_pointer == read_pointer-1) begin
				full <= 1'b1;
			end
			else if (reading && full) begin 
				full <= 1'b0;
			end 

			// Almost Full
			//---------
			if (writing && !reading &&  write_pointer == read_pointer-2) begin
				almost_full <= 1'b1;
			end
			else if (reading && !writing && !full) begin 
				almost_full <= 1'b0;
			end 

			// Empty
			//---------
			if (reading && !writing && (read_pointer==write_pointer-1) ) begin 
				empty <= 1'b1;
			end
			else if (writing && empty) begin 
				empty <= 1'b0;
			end

			// Almost Empty
			//---------
			if (reading && !writing &&  read_pointer == write_pointer-2) begin
				almost_empty <= 1'b1;
			end
			else if (writing && !reading && !empty) begin 
				almost_empty <= 1'b0;
			end 

		end
	end

	




endmodule
