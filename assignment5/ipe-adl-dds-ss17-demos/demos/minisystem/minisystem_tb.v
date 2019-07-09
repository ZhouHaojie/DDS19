`timescale 10ns/10ps
module minisystem_tb;


	logic clk;
	logic res_n;

	wire tb_data_in;
	wire tb_data_out;
	logic cable_connected;
	integer i;

	logic [23:0] transmit_data;
	logic transmit_data_valid;
	logic transmit_data_consumed;


	always #5 clk <= ~ clk;

	initial begin
		
		`ifndef IRUN
		$dumpfile("minisystem_tb.vcd");
		$dumpvars();
		`endif
		
		// init
		transmit_data = {24{1'b0}};
		transmit_data_valid = 0;
		cable_connected = 0;

		// reset
		clk = 0;
		res_n = 0;
		#200 res_n = 1;

		// Initiate Link
		//------------------------
		@(negedge clk);
		cable_connected = 1;



		// Send blocks of data to enable/disable the counter
		//---------------------------
		#243 sendBlocking({16'h0000,8'h00});
		sendBlocking({16'h0001,8'h00});
		sendBlocking({16'h0002,8'h00});

		//#243 sendSync();
		//sendBlock(32'h555555_03);

		// Finish
		//------------------
		`ifndef IRUN
		#500 $dumpoff();
		`endif
		#15000 $finish();

	end

	/*task sendSync;
		sendBlock(32'h55555555);
		sendBlock(32'h55555554);
	endtask

	task sendBlock(input [31:0] data);

		for ( i = 31 ; i >=0; i--) begin 
			@(negedge clk);
			data_in = data[i];
		end
	endtask*/

	// Send one pieace of data and wait for link to indicate consumption
	task sendBlocking(input [23:0] data);

			@(negedge clk);
			transmit_data = data[23:0];
			transmit_data_valid = 1;
			@(posedge transmit_data_consumed);
			transmit_data_valid = 0;
	endtask

	

	//-- Counter Link
	link tblink (

		.clk(clk),
		.res_n  (res_n),

		.cable_connected(cable_connected),

		.data_in(tb_data_in),
		.data_out(tb_data_out),

		.transmit_data(transmit_data),
		.transmit_data_valid(transmit_data_valid),
		.transmit_data_consumed(transmit_data_consumed)

	);

	//-- System Top

	minisystem_top minisystem_top (

		.PAD_CLK(clk),
		.PAD_RESN  (res_n),

		.PAD_CABLECONNECTED(cable_connected),

		.PAD_DATAIN(tb_data_out),
		.PAD_DATAOUT(tb_data_in)
	);

endmodule // minisystem_tb