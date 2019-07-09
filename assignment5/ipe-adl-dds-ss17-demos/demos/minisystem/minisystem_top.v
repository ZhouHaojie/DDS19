`timescale 10ns/10ps
module minisystem_top (

	// Clock say 500Mhz
	input PAD_CLK,

	input PAD_RESN,

	input  PAD_CABLECONNECTED,
	input  PAD_DATAIN,
	output PAD_DATAOUT

);


	// IO Cells
	//------------------

	IUMA clk_io (
        .PAD(PAD_CLK), // IO signal from counter_top
        .DI(clk), // Internal wire for counter
        .OE(1'b0), // Next: Enable signals for IO Features
        .PIN1(), .PIN2(), 
        .SMT(1'b0),.SR(), 
        .PD(1'b0), .PU(1'b0),.DO());

	IUMA resn_io (
        .PAD(PAD_RESN), // IO signal from counter_top
        .DI(res_n), // Internal wire for counter
        .OE(1'b0), // Next: Enable signals for IO Features
        .PIN1(), .PIN2(), 
        .SMT(1'b0),.SR(), 
        .PD(1'b0), .PU(1'b0),.DO());

	IUMA cableconnect_io (
        .PAD(PAD_CABLECONNECTED), // IO signal from counter_top
        .DI(cable_connected), // Internal wire for counter
        .OE(1'b0), // Next: Enable signals for IO Features
        .PIN1(), .PIN2(), 
        .SMT(1'b0),.SR(), 
        .PD(1'b0), .PU(1'b0),.DO());

	IUMA datain_io (
        .PAD(PAD_DATAIN), // IO signal from counter_top
        .DI(data_in), // Internal wire for counter
        .OE(1'b0), // Next: Enable signals for IO Features
        .PIN1(), .PIN2(), 
        .SMT(1'b0),.SR(), 
        .PD(1'b0), .PU(1'b0),.DO());

	IUMA dataout_io (
        .PAD(PAD_DATAOUT), // IO signal from counter_top
        .DI(), // Internal wire for counter
        .OE(1'b1), // Next: Enable signals for IO Features
        .PIN1(), .PIN2(), 
        .SMT(1'b0),.SR(), 
        .PD(1'b0), .PU(1'b0),.DO(data_out));

	/*wire clk = PAD_CLK;
	wire res_n = PAD_RESN;
	wire cable_connected = PAD_CABLECONNECTED;
	wire data_in = PAD_DATAIN;
	wire data_out = PAD_DATAOUT;*/


	
	// Clock
	//  clk is 500Mhz
	//  clk_slow divides by 4 using shift register
	//-------------------
	reg [3:0] 		clk_div_sr; // Slow clock
	wire 		  	clk_slow = clk_div_sr[3];

	// Reset generation for the slow clock domain
	reg  [5:0]    	res_n_clk_slow_sr;
	wire 			res_n_clk_slow = res_n_clk_slow_sr[5];

	//-- Generate slow clock from fast clock
	always @(posedge clk or negedge res_n) begin
		if(!res_n) begin
			 clk_div_sr <= 4'b0001;

		end else begin
			 clk_div_sr <= {clk_div_sr[2:0],clk_div_sr[3]};
		end
	end

	//-- Reset is set based on fast clock rasync reset, then updated based on slow clock to be synchronous with it
	always @(posedge clk_slow or negedge res_n) begin
		if(!res_n) begin
			 res_n_clk_slow_sr <= 6'b000001;
		end else begin

			 // As long as reset is 0, keep shifting until one reached
			 if (!res_n_clk_slow)
			 	res_n_clk_slow_sr <= {res_n_clk_slow_sr[4:0],1'b1};
		end
	end


	// Input -> FIFO
	// data_in is serial and receives blocks of 32 bits on CLOCK posedge
	// 32 bits:
	//  - 24bits payload MSB
	//  - 8bits  header
	//    - header[0] = 0 if IDLE , 1 if not IDLE
	//-----------------------

	//-- FIFO and Signals
	wire serial_in_shiftin;
	wire serial_in_full;
	wire serial_in_almost_full;
	wire serial_in_empty;
	wire serial_in_almost_empty;
	wire [23:0] serial_in_data;

	//-- Data consumption
	wire [23:0] received_data;
	reg serial_in_consume;
	reg [2:0] serial_in_consume_sync;
	reg       serial_in_consume_in_clk;
	reg       serial_in_consume_waitforone;

	//-- Protocol
	wire [7:0] payload_adress = received_data[1:0];
	wire [15:0] payload_data = received_data[23:8];

	//-- Config memory
	reg [15:0] cmem [3:0];

	//-- Transmit
	wire transmit_almost_full;
	reg  [23:0] transmit_data;
	reg  transmit_data_shiftin;

	//-- Instance and logic

	//-- Data consume
	always @(posedge clk or negedge res_n) begin 
		if(~res_n) begin
			serial_in_consume_sync <= 3'b000;
			serial_in_consume_in_clk <= 0;
			serial_in_consume_waitforone <= 1;
		end else begin

			serial_in_consume_sync <= {serial_in_consume_sync[1:0],serial_in_consume};

			if (serial_in_consume_sync[2]==3'b1 && serial_in_consume_waitforone==1) begin 
				serial_in_consume_in_clk <= 1'b1;
				serial_in_consume_waitforone <= 0;
			end
			else if (serial_in_consume_sync[2]==3'b0 && serial_in_consume_waitforone==0) begin 
				serial_in_consume_waitforone <= 1;
			end
			else begin
				serial_in_consume_in_clk <= 1'b0;
			end
			 
		end
	end

	wire [23:0] link_transmit_data;
	wire link_transmit_data_valid;
	wire link_transmit_data_consumed;

	link link_I ( 

		.clk(clk),
		.res_n(res_n),

		.data_in(data_in),
		.data_out(data_out),

		.cable_connected(cable_connected),
		
		.receive_data(serial_in_data),
		.receive_data_valid(serial_in_shiftin),
		.receive_data_consumed(1'b0),


		.transmit_data         (link_transmit_data),
		.transmit_data_valid   (link_transmit_data_valid),
		.transmit_data_consumed(link_ransmit_data_consumed)

	);

	async_fifo  #(
			.DSIZE(24),
			.ASIZE(9),
			.PIPELINED(0)
		)  fifo_input (
		
			.wclk(clk),
			.wres_n(res_n),
		
			.rclk(clk_slow),
			.rres_n(res_n_clk_slow),
		
			.shift_in(serial_in_shiftin),
			.d_in(serial_in_data),
			
			.d_out(received_data),
			.shift_out(serial_in_consume_in_clk),
	
			.full(fserial_in_ull),
			.almost_full(serial_in_almost_full),
			.empty(serial_in_empty),
			.almost_empty(serial_in_almost_empty),
		
			
			
			.inc_wptr(1'b0),
			.dec_wptr(1'b0),
			.wptr_value(),
			.inc_rptr(1'b0),
			.dec_rptr(1'b0),
			.rptr_value(),
			
			
			.sec(), 
			.ded()  
		
		
		);

		async_fifo  #(
			.DSIZE(24),
			.ASIZE(9),
			.PIPELINED(0)
		)  fifo_output (
		
			.wclk(clk_slow),
			.wres_n(res_n_clk_slow),
		
			.rclk(clk),
			.rres_n(res_n),
		
			.shift_in(transmit_data_shiftin),
			.d_in(transmit_data),
			
			.d_out(link_transmit_data),
			.shift_out(link_transmit_data_consumed),
	
			.full(),
			.almost_full(),
			.empty(link_transmit_data_valid),
			.almost_empty(),
		
			
			
			.inc_wptr(1'b0),
			.dec_wptr(1'b0),
			.wptr_value(),
			.inc_rptr(1'b0),
			.dec_rptr(1'b0),
			.rptr_value(),
			
			
			.sec(), 
			.ded()  
		
		
		);

	
	// Counters and data
	//---------------------------
	reg counter1_current_toggle;
	always @(posedge clk_slow or negedge res_n_clk_slow) begin
		if(!res_n_clk_slow) begin
			serial_in_consume <= 1'b0;
			transmit_data <= {23{1'b0}};
			transmit_data_shiftin <= 0;
			cmem[0] <= 16'h0000;
			cmem[1] <= 16'h0000;
			counter1_current_toggle <= 0;

		end 
		else begin
			 
			// Payload in
			//-----------------
			if (!serial_in_empty) begin 

				serial_in_consume <= 1'b1;

				cmem[payload_adress] <= payload_data;



			end 
			else begin 
				serial_in_consume <= 1'b0;
			end

			// Counter values out
			//--------------------------
			if (!transmit_almost_full && cmem[0][3]!=counter1_current_toggle) begin 
				transmit_data <= {7'b0000000,cmem[0][3],8'h01,8'h01}; // Toggle event on counter 1 for value 1
				counter1_current_toggle <= cmem[0][3];
				transmit_data_shiftin <= 1;
			end
			else begin
				transmit_data_shiftin <= 0;
			end

		end
	end


	// Start with one counter
	counter_match #(.SIZE(16)) counter1 (

		.clk(clk_slow),
		.res_n(res_n_clk_slow),

		.reset(cmem[0][0]),
		.enable(cmem[0][1]),
		.compare      (cmem[1]),
		.compare_match(cmem[0][2]),
		.toggle       (cmem[0][3])

	);



	// 



endmodule // minisystem_top



