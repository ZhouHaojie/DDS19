module link (
	input clk,  
	input res_n, 


	// Physical
	//-------------------
	input cable_connected,
	input data_in,
	output data_out,

	// Receive interface
	//---------------------------

	output reg [23:0] receive_data,
	output reg receive_data_valid,
	input wire receive_data_consumed,

	// Transmit interface
	//---------------------
	input wire [23:0] transmit_data,
	input wire transmit_data_valid,
	output reg transmit_data_consumed
	
);

	
	//-----------------------

	//-- Protocol
	localparam HEADER_IDLE = 8'h00;
	localparam HEADER_DATA = 8'h01;

	//-- Igress
	//------------------
	

	//-- FIFO and Signals
	reg serial_in_shiftin;
	wire serial_in_full;
	wire serial_in_almost_full;
	wire serial_in_empty;
	wire serial_in_almost_empty;

	reg igress_data_done;

	//-- Serial in signals
	reg [31:0] serial_in_data;
	reg [4:0]  serial_in_count; // 5 bits for 32 bits input
	wire [7:0] serial_in_header = serial_in_data[7:0];

	reg [23:0] igress_buffer_space;

	wire igress_last_bit = serial_in_count == 31;

	//-- Egress
	//------------------
	reg 	   egress_next_data;
	reg [5:0]  egress_bit_time;
	reg [23:0] egress_buffer_space;
	reg [31:0] egress_data;

	assign data_out = egress_data[31];

	//-- Global FSM
	wire fsm_igress_data;
	wire fsm_igress_nocable;

	wire fsm_egress_idle;
	wire fsm_egress_data;
	wire fsm_egress_nocable;

	// FSMs
	//-------------------
	igress_fsm igress_fsm (

		.clk(clk), 
	    .res_n(res_n), 

		//-- Inputs
		.cable_connected(cable_connected), 
		.data_available(1'b0), 
		.data_done(1'b0), 

		//-- Outputs
		.data(fsm_igress_data),
		.nocable(fsm_igress_nocable)

	);

	egress_fsm egress_fsm (

		.clk(clk), 
	    .res_n(res_n), 

		//-- Inputs
		.cable_connected(cable_connected), 
		.data_available(1'b0), 
		.data_done(1'b0), 

		//-- Outputs
		.idle(fsm_egress_idle), 
		.data(fsm_egress_data),
		.nocable(fsm_egress_nocable)

	);

	// Input -> Output
	// data_in is serial and receives blocks of 32 bits on CLOCK posedge
	// 32 bits:
	//  - 24bits payload MSB
	//  - 8bits  header
	//    - header[0] = 0 if IDLE , 1 if not IDLE

	/**
		SYNC and IDLE header values:
		x0, x10, x01 xxxxxx11 is ok
		Values:
			8'h03 000000_11 -> WRITE
			8'h07 000001_11 -> READ
	*/
	always @(posedge clk or negedge res_n) begin 
		if(!res_n) begin
			 

			// sync_in_done <= 0;

			 receive_data_valid <= 0;
			 receive_data <= {24{1'b0}};

			 //-- Egress
			 egress_next_data <= 0;
			 egress_bit_time <= {6{1'b0}};
			 egress_buffer_space <= {24{1'b0}};
			 egress_data <= {32{1'b0}};

			 //-- Igress
			 serial_in_data <= {32{1'b0}};
			 serial_in_count <= 5'h00;
			 igress_buffer_space <= {24{1'b1}};
			 igress_data_done <= 0;

			 //-- Transmit
			 transmit_data_consumed <= 0;


		end else begin

			// EGRESS
			//-----------------

			//-- Enable data
			if(cable_connected && ( egress_bit_time==30 )) begin
				egress_next_data <= 1'b1;
			end
			else begin 
				egress_next_data <= 1'b0;
			end

			//-- Data selection
			//---------------

			//-- Cable connected, send IDLE right away
			if (cable_connected && fsm_egress_nocable) begin 
				egress_data <= {igress_buffer_space,HEADER_IDLE};
			end
			//-- On IDLE, send the input buffer space to the remote part
			else if ((fsm_egress_idle && egress_next_data) ) begin 

				if (transmit_data_valid) begin 
					egress_data <= {transmit_data,HEADER_DATA};
					transmit_data_consumed <= 1'b1;
				end
				else begin
					egress_data <= {igress_buffer_space,HEADER_IDLE};
				end
			end 
			else begin
				egress_data <= {egress_data[30:0],1'b0};
				transmit_data_consumed <= 1'b0;
			end

			

			//-- data out
			if ( (fsm_egress_idle || fsm_egress_data)) begin 
				egress_bit_time <= egress_bit_time +1;
			end
			else begin
				egress_bit_time <= 0;
			end



			// IGRESS
			//------------------

			//-- Shift in
			if (cable_connected && (fsm_igress_data)) begin 
				serial_in_data <= {serial_in_data[30:0],data_in};
				serial_in_count <= serial_in_count +1;
			end

			//-- Save Result
			if (cable_connected && igress_last_bit) begin
				//data_received <= serial_in_data;
				igress_data_done <= 1'b1;
			end
			else begin
				igress_data_done <= 1'b0;
			end

			//-- Data analysis
			if (igress_data_done) begin 

				//-- IDLE -> Save output buffer space
				if (serial_in_header==HEADER_IDLE) begin 
					egress_buffer_space <= serial_in_data[31:8];
				end
				else if (serial_in_header==HEADER_DATA) begin 
					receive_data <= serial_in_data[31:8];
					receive_data_valid <= 1'b1;
				end


			end
			else begin 
				receive_data_valid  <= 1'b0;
			end

			//-- Igress buffer space
			if (igress_data_done && serial_in_header==HEADER_DATA) begin 
				igress_buffer_space <= igress_buffer_space-1;
			end
			else if (receive_data_consumed) begin 
				igress_buffer_space <= igress_buffer_space+1;
			end

			
		end
	end




endmodule