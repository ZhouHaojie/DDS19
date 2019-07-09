
/*
 * Copyright (c) 2017 
 * All rights reserved.
 * 
 * - Computer Architecture Group, University of Heidelberg
 * 		Markus Mueller <markus.mueller@ziti.uni-heidelberg.de>
 * - EXTOLL GmbH
 * 		Mondrian Nueslle <mondrian.nuessle@extoll.de>
 * 
 * This file is confidential and may not be distributed.
 * 
 * Usage granted for the assignments of the "Design Digitaler Schlatkreise" Lecture,
 * ADL Group, University of Karlsruhe (KIT)
 * 
 * For other usages, please contact the Copyright holders for permission.
 *
 * 
 *
 * University of Heidelberg
 * Computer Architecture Group
 * B6 26
 * 68131 Mannheim
 * Germany
 * http://www.ra.ziti.uni-heidelberg.de
 *
 */ 
`default_nettype none

module async_fifo #(
`ifdef CAG_ASSERTIONS
		parameter DISABLE_EMPTY_ASSERT		= 0,
		parameter DISABLE_FULL_ASSERT		= 0,
		parameter DISABLE_SHIFT_OUT_ASSERT	= 0,
		parameter DISABLE_XCHECK_ASSERT		= 0,
`endif
		parameter DSIZE					= 18,
		parameter ASIZE					= 9,
		parameter ALMOST_EMTPY_THRES	= 1,
		parameter SPEC_SHIFT_OUT		= 0,
		parameter SPEC_SHIFT_IN			= 0,
		parameter ONE_INC_OUT			= 0,
		parameter ONE_INC_IN			= 0,
		parameter HANDSHAKE				= 1,
		parameter ALMOST_FULL_THRES		= 1,
		parameter USE_SRL				= 0,
		parameter PIPELINED				= 0,	// add a register behind RAM?
		parameter SRL_REGISTERED		= 0,	// add a register behind SRL Fifo
		parameter SRL_USE_BYPASS		= 0,	// make srl bypassable
		parameter I_KNOW_WHAT_I_DO		= 0		// This parameter is a timing improvement, which can cause data corruption if You are not cautious
												// the check if the increment decrement value overflows current ptr value has been removed!!!
	) (
		input wire				rclk,
		input wire				wclk,
		input wire				rres_n,
		input wire				wres_n,
		input wire				shift_in,
		input wire				shift_out,
		input wire				inc_wptr,
		input wire				dec_wptr,
		input wire [ASIZE:0]	wptr_value,
		input wire				inc_rptr,
		input wire				dec_rptr,
		input wire [ASIZE:0]	rptr_value,
		input wire [DSIZE-1:0]	d_in,
		output wire [DSIZE-1:0]	d_out,
		output wire [DSIZE-1:0]	d_out_nxt,
		output wire				full,
		output wire				almost_full,
		output wire				empty,
		output wire				almost_empty,
		output wire				sec, //valid within si_clk domain!!!
		output wire				ded  //valid within si_clk domain!!!
	);

	wire [DSIZE-1:0]	ram_dout;
	wire				ram_empty;
	wire				shift_out_ram;
	wire				reg_almost_full;
	wire				reg_almost_empty;

	reg					shift_in_reg;
	reg					dec_rptr_dly;

	assign shift_out_ram	= !reg_almost_full && !ram_empty && !dec_rptr;
	assign almost_empty		= reg_almost_empty;

	generate
		if (PIPELINED == 1)
		begin : pipe_gen
			reg 		shift_in_reg_dly;

			`ifdef ASYNC_RES
			always @(posedge rclk or negedge rres_n) `else
			always @(posedge rclk ) `endif
			begin
				if (!rres_n)
				begin
					shift_in_reg		<= 1'b0;
					shift_in_reg_dly	<= 1'b0;
				end
				else
				begin
					shift_in_reg_dly	<= shift_out_ram;
					shift_in_reg		<= shift_in_reg_dly;
				end
			end
		end
		else
		begin : no_pipe_gen
			`ifdef ASYNC_RES
			always @(posedge rclk or negedge rres_n) `else
			always @(posedge rclk ) `endif
			begin
				if (!rres_n)
					shift_in_reg	<= 1'b0;
				else
					shift_in_reg	<= shift_out_ram;
			end
		end
	endgenerate

	`ifdef ASYNC_RES
	always @(posedge rclk or negedge rres_n) `else
	always @(posedge rclk ) `endif
	begin
		if (!rres_n)
			dec_rptr_dly				<= 1'b0;
		else
			dec_rptr_dly				<= dec_rptr;
	end

	// orig_fifo is just a normal (non-FWFT) synchronous or asynchronous FIFO
	async_standard_fifo #(
		.DSIZE(DSIZE),
		.ASIZE(ASIZE),
		.SPEC_SHIFT_IN(SPEC_SHIFT_IN),
		.SPEC_SHIFT_OUT(SPEC_SHIFT_OUT),
		.HANDSHAKE(HANDSHAKE),
		.ONE_INC_OUT(ONE_INC_OUT),
		.ONE_INC_IN(ONE_INC_IN),
		.ALMOST_FULL_THRES(ALMOST_FULL_THRES),
		.PIPELINED(PIPELINED),
		.I_KNOW_WHAT_I_DO(I_KNOW_WHAT_I_DO)
	) async_fifo_I (
		.rclk(rclk),
		.wclk(wclk),
		.rres_n(rres_n),
		.wres_n(wres_n),
		.shift_in(shift_in),
		.shift_out(shift_out_ram),
		.inc_wptr(inc_wptr),
		.dec_wptr(dec_wptr),
		.wptr_value(wptr_value),
		.inc_rptr(inc_rptr),
		.dec_rptr(dec_rptr),
		.rptr_value(rptr_value),
		.d_in(d_in),
		.d_out(ram_dout),
		.full(full),
		.almost_full(almost_full),
		.empty(ram_empty),
		.almost_empty(),
		.sec(sec),
		.ded(ded)
	);

	generate
		if (USE_SRL)
		begin : reg_fifo_srl_gen
			srl_fifo_wrapper #(
`ifdef CAG_ASSERTIONS
				.DISABLE_EMPTY_ASSERT(DISABLE_EMPTY_ASSERT),
				.DISABLE_FULL_ASSERT(DISABLE_FULL_ASSERT),
				.DISABLE_SHIFT_OUT_ASSERT(DISABLE_SHIFT_OUT_ASSERT),
				.DISABLE_XCHECK_ASSERT(DISABLE_XCHECK_ASSERT),
`endif
				.WIDTH(DSIZE),
				.DEPTH(4+ALMOST_EMTPY_THRES+(PIPELINED*2)),
				.AEMPTY_THRES(ALMOST_EMTPY_THRES),
				.AFULL_THRES(1+PIPELINED),
				.REGISTERED(SRL_REGISTERED),
				.USE_BYPASS(SRL_USE_BYPASS)
			) srl_fifo_I (
				.clk(rclk),
				.res_n(rres_n),
				.clr(dec_rptr || dec_rptr_dly),
				.din(ram_dout),
				.shiftin(shift_in_reg),
				.shiftout(shift_out),
				.dout(d_out),
				.dout_nxt(d_out_nxt),
				.full(),
				.almost_full(reg_almost_full),
				.almost_full_nxt(),
				.almost_empty(reg_almost_empty),
				.empty(empty)
			);

			//assign d_out_nxt	= {DSIZE {1'b0}};
		end
		else
		begin : reg_fifo_gen
			fifo_reg #(
`ifdef CAG_ASSERTIONS
				.DISABLE_EMPTY_ASSERT(DISABLE_EMPTY_ASSERT),
				.DISABLE_FULL_ASSERT(DISABLE_FULL_ASSERT),
				.DISABLE_SHIFT_OUT_ASSERT(DISABLE_SHIFT_OUT_ASSERT),
				.DISABLE_XCHECK_ASSERT(DISABLE_XCHECK_ASSERT),
`endif
				.DSIZE(DSIZE),
				.ENTRIES(4+ALMOST_EMTPY_THRES+(PIPELINED*2)),
				.ALMOST_FULL_VAL(1+PIPELINED),
				.ALMOST_EMTPY_VAL(ALMOST_EMTPY_THRES)
			) reg_fifo_I (
				.clk(rclk),
				.res_n(rres_n),
				.clr(dec_rptr || dec_rptr_dly),
				.din(ram_dout),
				.shiftin(shift_in_reg),
				.shiftout(shift_out),
				.dout(d_out),
				.dout_nxt(d_out_nxt),
				.full(),
				.almost_full(reg_almost_full),
				.almost_full_nxt(),
				.almost_empty(reg_almost_empty),
				.empty(empty)
			);
		end
	endgenerate

`ifdef CAG_COVERAGE
	full_cov: cover property (@(posedge wclk) disable iff(!wres_n) (full == 1'b1));
	almost_full_cov: cover property (@(posedge wclk) disable iff(!wres_n) (almost_full == 1'b1));
	empty_cov: cover property (@(posedge rclk) disable iff(!rres_n) (empty == 1'b1));
	almost_empty_cov: cover property (@(posedge rclk) disable iff(!rres_n) (almost_empty == 1'b1));
`endif // CAG_COVERAGE

`ifdef CAG_ASSERTIONS
	final
	begin
		if (DISABLE_FULL_ASSERT == 0)
		begin
			full_set_assert:				assert (!full);
			almost_full_set_assert:			assert (!almost_full);
		end

		if (DISABLE_EMPTY_ASSERT == 0)
		begin
			almost_empty_not_set_assert:	assert (almost_empty);
			empty_not_set_assert:			assert (empty);
		end
	end
`endif // CAG_ASSERTIONS

endmodule

`default_nettype wire