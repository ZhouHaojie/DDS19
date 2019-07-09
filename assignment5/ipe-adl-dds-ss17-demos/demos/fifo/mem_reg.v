module mem_reg #(parameter DWIDTH=16, parameter AWIDTH=8) (

	input wire clk,
	input wire res_n,

	input wire write,
	input wire [AWIDTH-1:0] write_address,
	input wire [DWIDTH-1:0] write_data,

	input wire read,
	input wire [AWIDTH-1:0] read_address,
	output reg [DWIDTH-1:0] read_data

);

	localparam DEPTH = 2 ** AWIDTH;
	reg [DWIDTH-1:0] memory [DEPTH:0];

	always @(posedge clk or negedge res_n) begin
		if (!res_n) begin
			// reset
			read_data <= {DWIDTH {1'b0}};
			
		end
		else  begin
			
			// Read
			//---------
			if (read) begin
				read_data <= memory[read_address];
			end

			// Write
			//------------
			if (write) begin
				memory[write_address] <= write_data;
			end

		end
	end


endmodule