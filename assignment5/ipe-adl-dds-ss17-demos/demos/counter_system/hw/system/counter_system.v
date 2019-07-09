module counter_system #(parameter COUNTERS = 4 ) (
		
		input clk,
		input res_n,
		
		input instruction_available,
		input [31:0] instruction,
		output reg next_instruction,
		
		// Special Features
		output reg [31:0] gpio
		
		);
	  
	// Local Control
	//--------------------
	reg internal_reset_n;
	wire real_res_n = internal_reset_n & res_n;
	
	// Counters Interface
	//---------------------
	localparam CSIZE = 32;
	wire [CSIZE-1:0] counter_values [COUNTERS];
	reg [CSIZE-1:0] counter_comparehigh[COUNTERS];
	reg [CSIZE-1:0] counter_comparelow[COUNTERS];
	reg [7:0] counter_status [COUNTERS];
	
	
	// Counter Instances
	//-----------------------
	genvar i;
	generate
		for (i=0;i<COUNTERS;i = i +1 ) begin
			always @(posedge clk) begin
				if (real_res_n==0) begin
					counter_status[i] <= 8'h00;
				end
			end
			counter #(.WIDTH(CSIZE)) counter_I (
					.clk(clk),
					.res_n(real_res_n),
					.enable(counter_status[i][0]),
					.reinit(counter_status[i][1]),
					.clear_overflow(counter_status[i][2]), 
					.value(counter_values[i])
				);
		end
	endgenerate
	
	// Memory
	//--------------
	reg [31:0] memory [1024];
	
	// Microengine
	//-------------------
	reg [31:0] r0;
	reg [31:0] r1;
	
	//-- Async read
	wire read_value = instruction[3:0]==4'hA || instruction[3:0]==4'hB ;
	reg [31:0] read_value_res;
	always @(*) begin
		if(read_value) begin
			
			casex (instruction_t1[24:8])
				
				{16'h0001}: begin
					read_value_res = { {24{1'b0}} , counter_status[0] };
				end
				{16'h0002}: begin
					read_value_res = {{24{1'b0}},counter_status[1]};
				end
				{16'h0003}: begin
					read_value_res = {{24{1'b0}},counter_status[2]};
				end
				{16'h0004}: begin
					read_value_res = {{24{1'b0}},counter_status[3]};
				end				
				
				default: begin
					read_value_res = {32{1'b0}};
				end		
			endcase
		
		end
		else begin
			read_value_res = {32{1'b0}};
		end
	end
	
	//-- Async Write select
	wire write_value = instruction_t1[3:0]==4'hC || instruction_t1[3:0]==4'hD ;
	reg [31:0] write_value_res;
	always @(*) begin
		if(write_value) begin
			write_value_res = instruction_t1[3:0]==4'hC ? r0 : r1;
			
		end
		else begin
			write_value_res = {32{1'b0}};
		end
	end
	
	//-- instruction processor
	wire next_is_data = instruction_t1[7:0] == 8'h10 ||  instruction_t1[7:0] == 8'h11 ;
	reg process_instruction;
	reg [31:0] instruction_t1;
	//wire next_is_data
	always @(posedge clk) begin
		if (res_n==0) begin
			
			next_instruction <= 1'b1;
			internal_reset_n <= 1'b0;
			r0 <= {32{1'b0}};
			r1 <= {32{1'b0}};
			//next_is_data <= 1'b0;
			gpio <=  {32{1'b0}};
			instruction_t1 <= {32{1'b0}};
			process_instruction <= 1'b0;
		end
		else begin
			
			// Read instruction or data
			//-------------
			if (instruction_available && !next_is_data) begin 
				instruction_t1 <= instruction;
				process_instruction <= 1'b1;
			end
			else if (!instruction_available) begin
				process_instruction <= 1'b0;
			end
			
			   
			// instructions
			//----------
			if (process_instruction) begin 
				casex (instruction_t1)
					
					// Reset
					//--------------------
					{ 24'hxx_xx_xx,8'hFF}: begin
						internal_reset_n <= 1'b0;
					end
					// NOOP
					{ 24'hxx_xx_xx,8'hFE}: begin
					end					
					// Release reset
					{ 24'hxx_xx_xx,8'h01}: begin
						internal_reset_n <= 1'b1;
					end				
					
					// Status
					//----------------
					{ 24'hxx_xx_xx,8'h02}: begin
						counter_status[instruction[15:8]] <= instruction[23:16];
					end		
					
					// Read
					//-------------------
					{ 24'hxx_xx_xx,8'h0A}: begin
						r0 <= read_value_res;
					end	
					{ 24'hxx_xx_xx,8'h0B}: begin
						r1 <= read_value_res;
					end	
					
					// Write
					//-------------------
					{ 24'hxx_xx_xx,8'h0C},{ 24'hxx_xx_xx,8'h0D}: begin
						casex (instruction_t1[24:8])
					
							{16'h0000}: begin
								counter_status[0] <= write_value_res[7:0];
							end
							{16'h0001}: begin
								counter_status[1] <=  write_value_res[7:0];
							end
							{16'h0002}: begin
								counter_status[2] <=  write_value_res[7:0];
							end
							{16'h0003}: begin
								counter_status[3] <=  write_value_res[7:0];
							end	
							
							{16'h0004}: begin
								counter_comparehigh[0] <= r0;
								counter_comparelow[0] <= r1;
							end
							{16'h0005}: begin
								counter_comparehigh[1] <= r0;
								counter_comparelow[1] <= r1;
							end
							{16'h0006}: begin
								counter_comparehigh[2] <= r0;
								counter_comparelow[2] <= r1;
							end
							{16'h0007}: begin
								counter_comparehigh[3] <= r0;
								counter_comparelow[3] <= r1;
							end	
							{16'h0008}: begin
								gpio <= write_value_res;
							end								
					
							default: begin
								//read_value_res = {32{1'b0}};
							end		
						endcase					
						//r0 <= read_value_res;
					end	
					
					// R0 -> R1
					{ 24'hxx_xx_xx,8'h0E}: begin
						r1 <= r0;
					end
					
					// R1 -> R0
					{ 24'hxx_xx_xx,8'h0F}: begin
						r0 <= r1;
					end	
					
					// Data -> R0 
					{ 24'hxx_xx_xx,8'h10}: begin
						//next_is_data <= !next_is_data;
						r0 <= instruction;
						instruction_t1 <= 32'h000000FE;
					end
					
					// Data -> R1
					{ 24'hxx_xx_xx,8'h11}: begin
						//next_is_data <= !next_is_data;
						r1 <= instruction;
						instruction_t1 <= 32'h000000FE;
					end						
					
					// Manipulation
					//--------------------
					
					// BIT 1
					{ 24'hxx_xx_xx,8'hA1}: begin
						if(instruction_t1[15:8]==0) begin
							r0 <= r0| ( 1 << instruction_t1[19:16] );
						end
						else begin
							r1 <= r1 | ( 1 << instruction_t1[19:16] );
						end
					end
					// BIT 0
					{ 24'hxx_xx_xx,8'hA2}: begin
						if(instruction_t1[15:8]==0) begin
							r0 <= r0 & ~( {32{1'b0}} | ( 1 << instruction_t1[19:16]) );
						end
						else begin
							r1 <= r1 & ~( {32{1'b0}} | ( 1 << instruction_t1[19:16]) );
						end
					end	
					// Shift Right
					{ 24'hxx_xx_xx,8'hA3}: begin
						if(instruction_t1[15:8]==0) begin
							r0 <= {1'b0,r0[31:1]} ;
						end
						else begin
							r1 <= {1'b0,r1[31:1]} ;
						end
					end	
					// Shift Left
					{ 24'hxx_xx_xx,8'hA4}: begin
						if(instruction_t1[15:8]==0) begin
							r0 <= {r0[30:0],1'b0} ;
						end
						else begin
							r1 <= {r1[30:0],1'b0} ;
						end
					end						
					
					 
					
					/*{ 24'hxx_xx_xx,8'h0B}: begin
						r1 <= read_value_res;
					end		*/				
					
					default: begin
					end
				endcase

			end
			
		end
		
		
	end

	
	
	
	
endmodule