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

module async_fifo_two_threshold #(
		parameter DSIZE					= 18,
		parameter ASIZE					= 10,
		parameter ALMOST_EMTPY_THRES	= 1,
		parameter SPEC_SHIFT_OUT		= 0,
		parameter SPEC_SHIFT_IN			= 0,
		parameter ONE_INC_OUT			= 0,
		parameter ONE_INC_IN			= 0,
		parameter HANDSHAKE				= 0,
		parameter ALMOST_FULL_THRES		= 1,
		parameter ALMOST_FULL_THRES_2	= 1,
		parameter USE_SRL				= 1,
		parameter PIPELINED				= 0,	// add a register behind RAM?
		parameter SRL_REGISTERED		= 0,	// add a register behind SRL Fifo
		parameter SRL_USE_BYPASS		= 0,	// make srl bypassable
		parameter I_KNOW_WHAT_I_DO		= 0		// This parameter is a timing improvement, which can cause data corruption if You are not cautious
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
		output wire				almost_full_2,
		output wire				empty,
		output wire				almost_empty
	);

	wire [DSIZE-1:0]	ram_dout;
	wire				ram_empty;
	wire				shift_out_ram;
	wire				reg_almost_full;

	reg					shift_in_reg;

	assign shift_out_ram	= !reg_almost_full && !ram_empty && !dec_rptr;

	generate
	begin: pipe_gen
		if (PIPELINED == 1)
		begin
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
		begin
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
	end
	endgenerate

	// orig_fifo is just a normal (non-FWFT) synchronous or asynchronous FIFO
	async_standard_fifo_two_threshold #(
		.DSIZE(DSIZE),
		.ASIZE(ASIZE),
		.SPEC_SHIFT_IN(SPEC_SHIFT_IN),
		.SPEC_SHIFT_OUT(SPEC_SHIFT_OUT),
		.HANDSHAKE(HANDSHAKE),
		.ONE_INC_OUT(ONE_INC_OUT),
		.ONE_INC_IN(ONE_INC_IN),
		.ALMOST_FULL_THRES(ALMOST_FULL_THRES),
		.ALMOST_FULL_THRES_2(ALMOST_FULL_THRES_2),
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
		.almost_full_2(almost_full_2),
		.empty(ram_empty)
	);

	generate
	begin: reg_fifo_gen
		if (USE_SRL)
		begin
			srl_fifo_wrapper #(
				.WIDTH(DSIZE),
				.AEMPTY_THRES(ALMOST_EMTPY_THRES),
				.AFULL_THRES(1+PIPELINED),
				.REGISTERED(SRL_REGISTERED),
				.USE_BYPASS(SRL_USE_BYPASS)
			) srl_fifo_I (
				.clk(rclk),
				.res_n(rres_n),
				.clr(dec_rptr),
				.din(ram_dout),
				.shiftin(shift_in_reg),
				.shiftout(shift_out),
				.dout(d_out),
				.full(),
				.almost_full(reg_almost_full),
				.almost_full_nxt(),
				.almost_empty(almost_empty),
				.empty(empty)
			);

			assign d_out_nxt	= {DSIZE {1'b0}};
		end
		else
		begin
			fifo_reg #(
				.DSIZE(DSIZE),
				.ENTRIES(2+ALMOST_EMTPY_THRES+PIPELINED),
				.ALMOST_FULL_VAL(1+PIPELINED),
				.ALMOST_EMTPY_VAL(ALMOST_EMTPY_THRES)
			) reg_fifo_I (
				.clk(rclk),
				.res_n(rres_n),
				.clr(dec_rptr),
				.din(ram_dout),
				.shiftin(shift_in_reg),
				.shiftout(shift_out),
				.dout(d_out),
				.dout_nxt(d_out_nxt),
				.full(),
				.almost_full(reg_almost_full),
				.almost_full_nxt(),
				.almost_empty(almost_empty),
				.empty(empty)
			);
		end
	end
	endgenerate
endmodule

`default_nettype wire
