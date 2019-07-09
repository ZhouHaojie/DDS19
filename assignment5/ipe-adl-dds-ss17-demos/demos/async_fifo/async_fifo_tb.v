module async_fifo_tb;
	
	logic clk_write;
	logic res_n_write;
	
	logic clk_read;
	logic res_n_read;	
	
	logic almost_empty;
	logic empty;
	logic almost_full;
	logic full;
	
	// Write
	logic [31:0] writeData;
	logic writeEnable;
	
	// Read
	wire [31:0] d_out;
	logic readEnable;
	logic [31:0] readData;
	
	logic [0:1024] currentTest ;
	

	// Utils
	//------------
	task writeToFifo
		(input [31:0] data);
		
		
		writeEnable = 1;
		writeData = data;
		@(negedge clk_write);
		writeEnable = 0;
		
	endtask
	
	// d_out always has the latest data, read enable requests next
	task readFromFifo(
		output [31:0] out);
		
		out = d_out;
		readEnable = 1;
		@(negedge clk_read);
		readEnable = 0;
	
		
	endtask
	
	// Clock
	//----------
	always begin
		#8.3 clk_write <= ~ clk_write;
	end
	
	always begin
		#15.2 clk_read <= ~ clk_read;
	end	
	
	// Initial Reset
	//-----------
	initial begin
		currentTest = "RESET";
		$dumpfile("async_fifo_tb.vcd");
		$dumpvars();		
		
		writeData = {32{1'b0}};
		writeEnable = 0;
		
		readData = 0;
		readEnable = 0;
		
		clk_read = 0;
		clk_write = 0;
		res_n_write=0;
		res_n_read=0;
		
		// Start
		#200 res_n_write =1;
		res_n_read =1;
	end
	// Tests
	//--------------
	integer i = 0;
	initial begin
		wait(res_n_write==1);
		wait(res_n_read==1);
		
		
		currentTest = "WRITE ONE WORD";
		@(negedge clk_write);
		writeToFifo($random());
		
		wait(empty==0);
		currentTest = "READ ONE WORD";
		@(negedge clk_read);
		readFromFifo(readData);
		
		wait(empty==1);
		currentTest = "WRITE FULL";
		@(negedge clk_write);
		for (i =0; i<517;i = i+1) begin	
			writeToFifo($random());
		end
		

		#500  currentTest = "FINISH";
		#500 $dumpoff();
		$finish();
	
	end
	


	 
	// FIFO
	// Make sure parameters are adapted to RAM size
	//----------------
	async_fifo  #(
			.DSIZE(32),
			.ASIZE(9),
			.PIPELINED(0)
		)  fifo (
		
			.wclk(clk_write),
			.wres_n(res_n_write),
		
			.rclk(clk_read),
			.rres_n(res_n_read),
		
			.shift_in(writeEnable),
			.d_in(writeData),
			
			.d_out(d_out),
			.shift_out(readEnable),
	
			.full(full),
			.almost_full(almost_full),
			.empty(empty),
			.almost_empty(almost_empty),
		
			
			
			.inc_wptr(1'b0),
			.dec_wptr(1'b0),
			.wptr_value(),
			.inc_rptr(1'b0),
			.dec_rptr(1'b0),
			.rptr_value(),
			
			
			.sec(), 
			.ded()  
		
		
		);
	

	
	
endmodule
	
	
	
	
