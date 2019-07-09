module system_tb;
	

	reg clk;
	reg res_n;

	reg newInstructions;
	
	wire [31:0] gpio;
	
	wire Sin = gpio[0];
	wire Clk1 = gpio[1];
	wire Clk2 = gpio[2];
	
	//reg  counterEnable;
	
	initial begin
		
		$dumpfile("system.vcd");
		$dumpvars();
		
		
		 
		// Initial Values
		//------------------
		newInstructions = 0;
		clk = 0;
		res_n = 0;
		
		// After 200ns, release full reset
		#200 res_n=1;
		
		//#200 newInstructions = 1;
		$readmemh("../instructions.list", instructions);
		pc = 0;
		eofProgram = 0;
		
		 
		
		#5000 $dumpoff();
		//$finish();
		//#1500000 $finish();
		 
		//$hello;
	end
	
	always #5 clk <= ~ clk;
	
	reg [31:0] instructions [1024];
	reg [31:0] instruction;
	reg eofProgram = 1;
	integer  pc = 0;
	wire instructionsAvailable = pc<1024 && !eofProgram;
	wire nextInstruction;
	
	initial begin
		for (pc=0;pc<1024; pc = pc+1) begin
			instructions[pc] = {32{1'b0}};
		end
		pc =0;
	end
	always @(posedge newInstructions) begin
		pc = 0;
		eofProgram = 0;
		$readmemh("instructions.list", instructions);
		$display("Instruction: %h",instructions[0]);
	end 
	always @(negedge clk) begin
		if (res_n && nextInstruction) begin
			
			instruction = instructions[pc];
			
			if (instruction==0) begin
				eofProgram = 1'b1;
			end
			
			pc = pc+1;
		end
	end
	    
	counter_system #(.COUNTERS(4)) dut (
			.clk(clk),
			.res_n(res_n),

			.instruction_available(instructionsAvailable),
			.instruction(instruction),
			.next_instruction(nextInstruction),
			.gpio(gpio)
			//.enable(counterEnable)
			//.compare_match(counterMatchEnable[0]),
			//.compare(counterCompare0)
		);
	
	
	
endmodule