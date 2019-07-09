/**
 reg fsm_cable_connected;
reg fsm_data_available;
reg fsm_data_done;

wire fsm_data;
wire fsm_nocable;

igress_fsm igress_fsm_I (

    .clk(), 
    .res_n(), 
	//-- Inputs
	.cable_connected(fsm_cable_connected), 
	.data_available(fsm_data_available), 
	.data_done(fsm_data_done), 

	//-- Outputs
	.data(fsm_data), 
	.nocable(fsm_nocable)
);

 */
module igress_fsm ( 
    input wire clk, 
    input wire res_n, 

    // Inputs
    //------------ 
    input wire cable_connected, 
    input wire data_available, 
    input wire data_done, 

    // Outputs
    //------------ 
    output wire data, 
    output wire nocable
 );

localparam WAIT_CABLE = 2'b01;
localparam DATA = 2'b10;

reg [1:0] current_state, next_state;
assign {data, nocable} = current_state;

wire [2:0] inputvector;
assign inputvector = {cable_connected, data_available, data_done};


always @(*) begin
  casex({inputvector, current_state})
    {3'b0x1, WAIT_CABLE},
    {3'b01x, WAIT_CABLE}:   next_state = WAIT_CABLE;
    {3'b1xx, WAIT_CABLE}:   next_state = DATA;
    {3'bx01, DATA},
    {3'b10x, DATA},
    {3'b0x1, DATA},
    {3'b01x, DATA},
    {3'bxx1, DATA}:   next_state = DATA;
    {3'b110, DATA}:   next_state = DATA;
    {3'b000, 2'bxx}:   next_state = WAIT_CABLE;
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

	tc_trans_1: cover property( @(posedge clk) disable iff (!res_n)(inputvector ==? 3'b1xx) &&(current_state == WAIT_CABLE)|=> (current_state == DATA));

	tc_trans_7_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == DATA)|=> (current_state == DATA) );

	tc_trans_8_default: cover property( @(posedge clk) disable iff (!res_n) (current_state == WAIT_CABLE)|=> (current_state == WAIT_CABLE) );

// synopsys translate_on
`endif


endmodule
