
`timescale 1ns/10ps
module single_counter_tb;
	
	localparam SIZE = 16;
	reg clk;
	reg res_n;
	
	reg counterEnable;
	reg counterResetEnable;
	reg counterMatchEnable;
	
	reg [SIZE-1:0] counterCompare;
	//reg  counterEnable;
	
	initial begin
		
		$dumpfile("demo_sim_top.vcd");
		$dumpvars();
		
		clk = 0;
		res_n = 0;
		 
		// Initial Values
		//------------------
		counterEnable = 0;
		counterResetEnable =0;
		counterMatchEnable =0;
		counterCompare = {SIZE{1'b0}};

		//counterEnable = 1;
		
		// After 200ns, release full reset
		#200 res_n=1;
		
		// Enable
		//-------------
		#150 @(negedge clk);
		counterEnable = 1;
		
		
		
		// Counter 1 is matching, at 1/4 of max value -> 25/75 Duty cycle
		//----------------
		//counterMatchEnable[1] = 1'b1;
		//counterCompare1 = (2**SIZE) / 4 ;
		
		
		
		#15000000 $dumpoff();
		$finish();
		//#1500000 $finish();
		
		//$hello;
	end
	
	always #5 clk <= ~ clk;
	
	
	counter #(.WIDTH(16)) counter (
		.clk(clk),
		.res_n(res_n),

		.enable(counterEnable)
		//.compare_match(counterMatchEnable[0]),
		//.compare(counterCompare0)
	);
	
	
	
	
endmodule