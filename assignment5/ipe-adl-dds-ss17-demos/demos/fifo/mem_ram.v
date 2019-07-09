module mem_ram #(parameter DWIDTH=16, parameter AWIDTH=8) (

	input wire clk,
	input wire res_n,

	input wire write,
	input wire [AWIDTH-1:0] write_address,
	input wire [DWIDTH-1:0] write_data,

	input wire read,
	input wire [AWIDTH-1:0] read_address,
	output wire [DWIDTH-1:0] read_data

);

	// RAM is 512x32
	// Padd the address and data signals with 0 to void warnings and such
	localparam RAMAWIDTH = 9;
	localparam RAMDWIDTH = 32;
	wire [RAMAWIDTH-1:0] write_address_padded = { { (RAMAWIDTH-AWIDTH) {1'b0} } , write_address};
	wire [RAMAWIDTH-1:0] read_address_padded = { { (RAMAWIDTH-AWIDTH) {1'b0} } , read_address};

	wire [RAMDWIDTH-1:0] write_data_padded = { { (RAMDWIDTH-DWIDTH) {1'b0} } , write_data};
	wire [RAMDWIDTH-1:0] read_data_ram;
	assign read_data = read_data_ram[DWIDTH-1:0];



	ram ram_I (
		.clk_a(clk),
		.wen_a(write),
		.addr_a(write_address_padded),
		.wdata_a(write_data_padded),

		.clk_b(clk),
		.ren_b(read),
		.addr_b(read_address_padded),
		.rdata_b(read_data_ram),
	
		// SEC/DED for single error/double error detection (ECC)
		// Not used, always return 0
		.sec(),
		.ded()
	);


endmodule