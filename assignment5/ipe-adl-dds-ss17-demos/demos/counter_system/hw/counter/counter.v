module counter #(parameter WIDTH=8) (
		
	input clk,
	input res_n,
	input enable,
	input reinit,
	input clear_overflow,
	output reg [WIDTH-1:0] value,
	output reg overflow
		
);
	
	// Signals
	//-------------
	wire last_value = value == (2**WIDTH-1);
	wire fsm_overflow;
	wire fsm_counting;
	
	// FSM
	//---------------
	counter_fsm counter_fsm_I (

		.clk(clk), 
		.res_n(res_n), 
		
		//-- Inputs
		.enable(enable), 
		.last_value(last_value), 
		.reinit(reinit), 
		.clear_overflow(clear_overflow), 		

		//-- Outputs
		.overflow(fsm_overflow), 
		.counting(fsm_counting)
	);
	
	// Main Logic
	//-----------------
	`ifdef ASYNC_RES
	always @(posedge clk or negedge res_n ) begin
	`else
	always @(posedge clk)  begin
	`endif	
	
		// Reset
		if (res_n==0) begin
			value <= {WIDTH{1'b0}};
		end
		// Main
		else begin
			
			// Counting -> count
			if (fsm_counting) begin
				value <= value + 1;
			end
			
		end
	end

	
endmodule