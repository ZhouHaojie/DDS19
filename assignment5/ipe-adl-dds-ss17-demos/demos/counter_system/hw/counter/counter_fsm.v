/**
 reg fsm_enable;
reg fsm_last_value;
reg fsm_reinit;
reg fsm_clear_overflow;

wire fsm_overflow;
wire fsm_counting;
wire fsm_idle;

counter_fsm counter_fsm_I (

    .clk(), 
    .res_n(), 
	//-- Inputs
	.enable(fsm_enable), 
	.last_value(fsm_last_value), 
	.reinit(fsm_reinit), 
	.clear_overflow(fsm_clear_overflow), 

	//-- Outputs
	.overflow(fsm_overflow), 
	.counting(fsm_counting), 
	.idle(fsm_idle)
);

 */
module counter_fsm ( 
    input wire clk, 
    input wire res_n, 

    // Inputs
    //------------ 
    input wire enable, 
    input wire last_value, 
    input wire reinit, 
    input wire clear_overflow, 

    // Outputs
    //------------ 
    output wire overflow, 
    output wire counting, 
    output wire idle
 );

localparam IDLE = 3'b001;
localparam COUNT = 3'b010;
localparam OVERFLOW = 3'b110;
localparam PAUSE = 3'b000;
localparam OVERFLOW_ERROR = 3'b100;

reg [2:0] current_state, next_state;
assign {overflow, counting, idle} = current_state;

wire [3:0] inputvector;
assign inputvector = {enable, last_value, reinit, clear_overflow};


always @(*) begin
  casex({inputvector, current_state})
    {4'bxx01, IDLE},
    {4'b0x0x, IDLE},
    {4'bxxx1, IDLE}:   next_state = IDLE;
    {4'b1x00, IDLE}:   next_state = COUNT;
    {4'b1x11, COUNT},
    {4'b10x1, COUNT},
    {4'b100x, COUNT},
    {4'bxx11, COUNT},
    {4'b1xx1, COUNT}:   next_state = COUNT;
    {4'b1100, COUNT}:   next_state = OVERFLOW;
    {4'b0x0x, COUNT}:   next_state = PAUSE;
    {4'bx000, OVERFLOW},
    {4'bxx11, OVERFLOW}:   next_state = OVERFLOW;
    {4'bxx01, OVERFLOW}:   next_state = COUNT;
    {4'bx100, OVERFLOW}:   next_state = OVERFLOW_ERROR;
    {4'bxx01, PAUSE},
    {4'b0x0x, PAUSE},
    {4'bxxx1, PAUSE}:   next_state = PAUSE;
    {4'b1x00, PAUSE}:   next_state = COUNT;
    {4'bxxx1, OVERFLOW_ERROR},
    {4'bxx0x, OVERFLOW_ERROR}:   next_state = OVERFLOW_ERROR;
    {4'bxx10, 3'bxxx}:   next_state = IDLE;
    default:  next_state = IDLE;
  endcase
end

`ifdef ASYNC_RES
 always @(posedge clk or negedge res_n ) begin
`else
 always @(posedge clk) begin
`endif
    if (!res_n)
    begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end

`ifdef CAG_COVERAGE
// synopsys translate_off

	// State coverage
	//--------

	//-- Coverage group declaration
	covergroup cg_states @(posedge clk);
		states : coverpoint current_state {
			bins IDLE = {IDLE};
			bins COUNT = {COUNT};
			bins OVERFLOW = {OVERFLOW};
			bins PAUSE = {PAUSE};
			bins OVERFLOW_ERROR = {OVERFLOW_ERROR};
		}
	endgroup : cg_states

	//-- Coverage group instanciation
	cg_states state_cov_I;
	initial begin
		state_cov_I = new();
		state_cov_I.set_inst_name("state_cov_I");
	end

	// Transitions coverage
	//--------

	tc_enable_Enable: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 4'b1x00) &&(current_state == IDLE)|=> (current_state == COUNT));

	tc_trans_2_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == COUNT)|=> (current_state == COUNT) );

	tc_overflow: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 4'b1100) &&(current_state == COUNT)|=> (current_state == OVERFLOW));

	tc_trans_4_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == IDLE)|=> (current_state == IDLE) );

	tc_trans_5: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 4'b0x0x) &&(current_state == COUNT)|=> (current_state == PAUSE));

	tc_trans_6_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == OVERFLOW)|=> (current_state == OVERFLOW) );

	tc_trans_7_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == PAUSE)|=> (current_state == PAUSE) );

	tc_trans_8: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 4'b1x00) &&(current_state == PAUSE)|=> (current_state == COUNT));

	tc_clear_overflow: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 4'bxx01) &&(current_state == OVERFLOW)|=> (current_state == COUNT));

	tc_trans_10: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 4'bx100) &&(current_state == OVERFLOW)|=> (current_state == OVERFLOW_ERROR));

	tc_trans_11_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == OVERFLOW_ERROR)|=> (current_state == OVERFLOW_ERROR) );

// synopsys translate_on
`endif


endmodule
