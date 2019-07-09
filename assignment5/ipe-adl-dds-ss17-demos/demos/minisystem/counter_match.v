module counter_match #(parameter SIZE = 8) (
		
		input 	wire 				clk,
		input 	wire 				res_n,
		input   wire				reset,
		
		input  	wire 				enable,
		
		input  	wire	[SIZE-1:0] 	compare,
		input  	wire    			compare_match,
		
		output 	reg 	[SIZE-1:0] 	value,
		output 	reg 				overflow,
		
		//-- Toggle output
		output 	reg 				toggle
);
	
	wire overflow_cycle = (value== (2**SIZE)-1);
	wire toggle_cycle = (compare_match && value==compare) || overflow_cycle;
	
	always @(posedge clk) begin
		
		if(!res_n || reset) begin
			value <= {SIZE{1'b0}};
			overflow <= 0;
			toggle <= 0;
		end
		else begin
			
			// Global Enable
			if (enable) begin
				
				
				value <= value + 1;
				
				//-- Overflow
				if (overflow_cycle) begin
					overflow <= 1;
				end
				else begin
					overflow <= 0;
				end
				
				//-- Toggle
				//-- On compare match or overflow
				if (toggle_cycle) begin
					toggle <= ! toggle;
				end
			end
			
		end
		
	end
	
	
endmodule
		