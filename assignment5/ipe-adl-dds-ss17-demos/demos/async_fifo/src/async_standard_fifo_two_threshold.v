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

module async_standard_fifo_two_threshold #(
		parameter DSIZE				= 8,
		parameter ASIZE				= 4,
		parameter SPEC_SHIFT_OUT	= 0,
		parameter SPEC_SHIFT_IN		= 0,
		parameter ONE_INC_OUT		= 0,
		parameter ONE_INC_IN		= 0,
		parameter HANDSHAKE			= 0,
		parameter ALMOST_FULL_THRES	= 1,
		parameter ALMOST_FULL_THRES_2 = 1,
		parameter PIPELINED			= 0,
		parameter I_KNOW_WHAT_I_DO	= 0	// This parameter is a timing improvement, which can cause data corruption if You are not cautious
	) (
		input wire				rclk,
		input wire				wclk,
		input wire				wres_n,
		input wire				rres_n,
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
		output wire				full,
		output wire				almost_full,
		output wire				almost_full_2,
		output wire				empty,
		output wire 				sec,
		output wire				ded
	);

	wire [ASIZE-1:0]	waddr, raddr;
	wire [ASIZE:0]		wptr, rptr, wq2_rptr, rq2_wptr;

	generate
	begin: w2r_sync
		if (HANDSHAKE == 1)
		begin
			sync_w2r_hs #(.ASIZE(ASIZE)) sync_w2r_I (
				.rclk(rclk),
				.wclk(wclk),
				.rres_n(rres_n),
				.wres_n(wres_n),
				.w_ptr(wptr),
				.r_ptr(rq2_wptr)
			);
		end
		else
		begin
			sync_w2r #(.ASIZE(ASIZE)) sync_w2r_I (
				.rclk(rclk),
				.rrst_n(rres_n),
				.wptr(wptr),
				.rq2_wptr(rq2_wptr)
			);
		end
	end
	endgenerate

	generate
	begin: r2w_sync
		if (HANDSHAKE == 1)
		begin
			sync_w2r_hs #(.ASIZE(ASIZE)) sync_r2w_I (
				.rclk(wclk),
				.wclk(rclk),
				.rres_n(wres_n),
				.wres_n(rres_n),
				.w_ptr(rptr),
				.r_ptr(wq2_rptr)
			);
		end
		else
		begin
			sync_r2w #(.ASIZE(ASIZE)) sync_r2w_I (
				.wclk(wclk),
				.wrst_n(wres_n),
				.rptr(rptr),
				.wq2_rptr(wq2_rptr)
			);
		end
	end
	endgenerate

	ram_1w1r_2c #(
		.DATASIZE(DSIZE),
		.ADDRSIZE(ASIZE),
		.PIPELINED(PIPELINED)
	) ram_I (
		.clk_a(wclk),
		.wen_a(shift_in && !full),
		.addr_a(waddr),
		.wdata_a(d_in),

		.clk_b(rclk),
		.ren_b(shift_out),
		.addr_b(raddr),
		.rdata_b(d_out),
		.sec(sec),
		.ded(ded)
	);

	generate
	begin: empty_logic
		if ((SPEC_SHIFT_OUT == 1) && (ONE_INC_OUT == 1))
		begin
			empty_logic_spec_shift_out_1_inc #(.ASIZE(ASIZE), .HANDSHAKE(HANDSHAKE)) empty_logic_I (
				.rclk(rclk),
				.rrst_n(rres_n),
				.rinc(shift_out),
				.inc_rptr(inc_rptr),
				.dec_rptr(dec_rptr),
				.rq2_wptr(rq2_wptr),
				.rempty(empty),
				.rptr(rptr),
				.raddr(raddr)
			);
		end
		else if (SPEC_SHIFT_OUT == 1)
		begin
			empty_logic_spec_shift_out #(.ASIZE(ASIZE), .HANDSHAKE(HANDSHAKE)) empty_logic_I (
				.rclk(rclk),
				.rrst_n(rres_n),
				.rinc(shift_out),
				.inc_rptr(inc_rptr),
				.dec_rptr(dec_rptr),
				.inc_dec_value(rptr_value),
				.rq2_wptr(rq2_wptr),
				.rempty(empty),
				.rptr(rptr),
				.raddr(raddr)
			);
		end
		else
		begin
			empty_logic #(.ASIZE(ASIZE), .HANDSHAKE(HANDSHAKE)) empty_logic_I (
				.rclk(rclk),
				.rrst_n(rres_n),
				.raddr(raddr),
				.rptr(rptr),
				.rq2_wptr(rq2_wptr),
				.rinc(shift_out),
				.rempty(empty)
			);
		end
	end
	endgenerate

	generate
	begin: full_logic
		if ((SPEC_SHIFT_IN == 1) && (ONE_INC_IN == 1))
		begin
			full_logic_spec_shift_in_1_inc #(.ASIZE(ASIZE), .HANDSHAKE(HANDSHAKE), .ALMOST_FULL_THRES(ALMOST_FULL_THRES)) full_logic_I (
				.wclk(wclk),
				.wrst_n(wres_n),
				.wfull(full),
				.walmost_full(almost_full),
				.winc(shift_in),
				.inc_wptr(inc_wptr),
				.dec_wptr(dec_wptr),
				.waddr(waddr),
				.wptr(wptr),
				.wq2_rptr(wq2_rptr)
			);
		end
		else if (SPEC_SHIFT_IN == 1)
		begin
			full_logic_spec_shift_in #(.ASIZE(ASIZE), .HANDSHAKE(HANDSHAKE), .ALMOST_FULL_THRES(ALMOST_FULL_THRES), .I_KNOW_WHAT_I_DO(I_KNOW_WHAT_I_DO)) full_logic_I (
				.wclk(wclk),
				.wrst_n(wres_n),
				.wfull(full),
				.walmost_full(almost_full),
				.winc(shift_in),
				.inc_wptr(inc_wptr),
				.dec_wptr(dec_wptr),
				.inc_dec_value(wptr_value),
				.waddr(waddr),
				.wptr(wptr),
				.wq2_rptr(wq2_rptr)
			);
		end
		else
		begin
			full_logic_two_threshold #(.ASIZE(ASIZE), .HANDSHAKE(HANDSHAKE), .ALMOST_FULL_THRES(ALMOST_FULL_THRES),.ALMOST_FULL_THRES_2(ALMOST_FULL_THRES_2)) full_logic_I (
				.wclk(wclk),
				.wrst_n(wres_n),
				.wfull(full),
				.walmost_full(almost_full),
				.walmost_full_2(almost_full_2),
				.winc(shift_in),
				.waddr(waddr),
				.wptr(wptr),
				.wq2_rptr(wq2_rptr)
			);
		end
	end
	endgenerate

endmodule

`default_nettype wire
