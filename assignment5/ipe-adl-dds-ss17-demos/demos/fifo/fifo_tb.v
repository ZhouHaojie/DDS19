`timescale 10ns/10ps

module fifo_tb;

	localparam AWIDTH = 3;
	localparam DWIDTH = 32;

	logic clk;
	logic res_n;

	logic shiftout;

	logic shiftin;
	logic [DWIDTH-1:0] data_in;

	logic empty;
	logic full;

	integer i = 0;


	initial begin
		
		`ifndef IRUN
		$dumpfile("fifo_tb.vcd");
		$dumpvars();
		`endif
				
		
		// reset
		clk = 0;
		res_n = 0;
		shiftin = 0;
		shiftout = 0;
		data_in = 0;
		#200 res_n = 1;

		// Single write/read to test empty
		//----------------
		#200 @(negedge clk);
		shiftin = 1;
		data_in = $random();
		@(negedge clk);
		shiftin = 0;

		

		#100 @(negedge clk);
		shiftout = 1;
		@(negedge clk);
		shiftout = 0;

		// Write one, almost empty is on, write another, almost emoty is gone
		//--------
		#200 @(negedge clk);
		shiftin = 1;
		data_in = $random();
		@(negedge clk);
		shiftin = 0;

		#50 @(negedge clk);
		shiftin = 1;
		data_in = $random();
		@(negedge clk);
		shiftin = 0;

		//-- Read one, almost empty is back
		#15 @(negedge clk);
		shiftout = 1;
		@(negedge clk);
		shiftout = 0;

		//-- Read one,  empty is back
		#15 @(negedge clk);
		shiftout = 1;
		@(negedge clk);
		shiftout = 0;
		

		// Full write
		//----------------
		for (i = 0 ; i< (2**AWIDTH) ; i = i+1) begin 
			 @(negedge clk);
			 shiftin = 1;
			 data_in = $random();
		end

		@(negedge clk);
		shiftin = 0;

		

		// Read once, full goes away
		//----------
		#100 @(negedge clk);
		shiftout = 1;
		@(negedge clk);
		shiftout = 0;

	

		// Read back to empty
		// One word was read before, so read max entries -1 back
		//---------------------
		for (i = 0 ; i< (2**AWIDTH)-1 ; i = i+1) begin 
			 @(negedge clk);
			 shiftout = 1;
		end
		@(negedge clk);
		shiftout = 0;

		//-- Empty should be one here
		
		//----------------
		// Simultaneaous write and read
		//----------------

		// Make one write, should not be empty (tested before)
		#200 @(negedge clk);
		shiftin = 1;
		data_in = $random();
		@(negedge clk);
		shiftin = 0;
		

		// Activate write and read, should stay not empty and almost empty
		#200 @(negedge clk);
		shiftin = 1;
		data_in = $random();
		shiftout = 1;
		@(negedge clk);
		shiftin = 0;
		shiftout = 0;

		// Another read brings back to empty
		#50 @(negedge clk);
		shiftout = 1;
		@(negedge clk);
		shiftout = 0;
		
		`ifndef IRUN
		#500 $dumpoff();
		`endif
		#500 $finish();
		//#1500000 $finish();
		
		//$hello;
	end
	
	always #5 clk <= ~ clk;


	`ifdef FIFO_MEM
		fifo_mem #(.DWIDTH(DWIDTH),.AWIDTH(AWIDTH),.MEM_RAM(`FIFO_RAM))
	`else 
		fifo #(.DWIDTH(DWIDTH),.AWIDTH(AWIDTH))
	`endif
	    fifo_I (

		.clk(clk),
		.res_n(res_n),

		.data_in(data_in),
		.shiftin(shiftin),

		.shiftout(shiftout),

		.empty(empty),
		.full(full)
	);


endmodule
