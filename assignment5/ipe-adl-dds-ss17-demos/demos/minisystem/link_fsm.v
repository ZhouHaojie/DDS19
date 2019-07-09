/**
 reg fsm_cable_connected;
reg fsm_sync_done;
reg fsm_data_available;
reg fsm_data_done;

wire fsm_sync;
wire fsm_idle;
wire fsm_data;

link_fsm link_fsm_I (

    .clk(), 
    .res_n(), 
	//-- Inputs
	.cable_connected(fsm_cable_connected), 
	.sync_done(fsm_sync_done), 
	.data_available(fsm_data_available), 
	.data_done(fsm_data_done), 

	//-- Outputs
	.sync(fsm_sync), 
	.idle(fsm_idle), 
	.data(fsm_data)
);

 */
module link_fsm ( 
    input wire clk, 
    input wire res_n, 

    // Inputs
    //------------ 
    input wire cable_connected, 
    input wire sync_done, 
    input wire data_available, 
    input wire data_done, 

    // Outputs
    //------------ 
    output wire sync, 
    output wire idle, 
    output wire data
 );

localparam WAIT_CABLE = 3'b000;
localparam SYNC = 3'b100;
localparam IDLE = 3'b010;
localparam DATA = 3'b001;

reg [2:0] current_state, next_state;
assign {sync, idle, data} = current_state;

wire [3:0] inputvector;
assign inputvector = {cable_connected, sync_done, data_available, data_done};


always @(*) begin
  casex({inputvector, current_state})
    {4'b0xx1, WAIT_CABLE},
    {4'b0x1x, WAIT_CABLE}:   next_state = WAIT_CABLE;
    {4'b1xxx, WAIT_CABLE}:   next_state = SYNC;
    {4'b1xx1, SYNC},
    {4'b1x1x, SYNC},
    {4'b10xx, SYNC},
    {4'bxxx1, SYNC},
    {4'bxx1x, SYNC}:   next_state = SYNC;
    {4'b1100, SYNC}:   next_state = IDLE;
    {4'bxx01, IDLE},
    {4'b1x0x, IDLE},
    {4'b0xx1, IDLE},
    {4'b0x1x, IDLE},
    {4'bxxx1, IDLE}:   next_state = IDLE;
    {4'b1x10, IDLE}:   next_state = DATA;
    {4'bxx10, DATA},
    {4'b1xx0, DATA},
    {4'b0xx1, DATA},
    {4'b0x1x, DATA}:   next_state = DATA;
    {4'b1xx1, DATA}:   next_state = IDLE;
    {4'b0x00, 3'bxxx}:   next_state = WAIT_CABLE;
    default:  next_state = WAIT_CABLE;
  endcase
end

`ifdef ASYNC_RES
 always @(posedge clk or negedge res_n ) begin
`else
 always @(posedge clk) begin
`endif
    if (!res_n)
    begin
        current_state <= WAIT_CABLE;
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
			bins WAIT_CABLE = {WAIT_CABLE};
			bins SYNC = {SYNC};
			bins IDLE = {IDLE};
			bins DATA = {DATA};
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

	tc_trans_1: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 4'b1xxx) &&(current_state == WAIT_CABLE)|=> (current_state == SYNC));

	tc_trans_2: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 4'b1100) &&(current_state == SYNC)|=> (current_state == IDLE));

	tc_trans_3: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 4'b1x10) &&(current_state == IDLE)|=> (current_state == DATA));

	tc_trans_4: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 4'b1xx1) &&(current_state == DATA)|=> (current_state == IDLE));

	tc_trans_5_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == DATA)|=> (current_state == DATA) );

	tc_trans_6_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == SYNC)|=> (current_state == SYNC) );

	tc_trans_7_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == IDLE)|=> (current_state == IDLE) );

	tc_trans_8_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == WAIT_CABLE)|=> (current_state == WAIT_CABLE) );

// synopsys translate_on
`endif


endmodule
