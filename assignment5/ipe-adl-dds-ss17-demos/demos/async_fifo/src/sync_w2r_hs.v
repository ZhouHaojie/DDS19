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

module sync_w2r_hs #(
		parameter ASIZE = 4
	) (
		input wire				rclk, wclk,
		input wire				rres_n, wres_n,
		input wire [ASIZE:0]	w_ptr,
		output reg [ASIZE:0]	r_ptr
	);

`ifndef ASIC
	(* ASYNC_REG="TRUE", SHIFT_EXTRACT="NO", HBLKNM="internal_reg"*)	reg [ASIZE:0] internal_reg;
	(* ASYNC_REG="TRUE", SHIFT_EXTRACT="NO", HBLKNM="wreq"*)			reg wreq;
	(* ASYNC_REG="TRUE", SHIFT_EXTRACT="NO", HBLKNM="rack"*)			reg rack;
`else
  reg [ASIZE:0] internal_reg;
  reg wreq;
  reg rack;
`endif

	wire	sync_wreq, sync_rack;

	// synchronizing hand-shake bit from write to read domain
	sync_w2r #(0) sync_w2r_I (
		.rclk(rclk),
		.rrst_n(rres_n),
		.wptr(wreq),
		.rq2_wptr(sync_wreq)
	);

	// synchronizing hand-shake bit from read to write domain
	sync_r2w #(0) sync_r2w_I (
		.wclk(wclk),
		.wrst_n(wres_n),
		.rptr(rack),
		.wq2_rptr(sync_rack)
	);

	// read side which samples the synchronized data
	`ifdef ASYNC_RES
	always @(posedge rclk or negedge rres_n) `else
	always @(posedge rclk ) `endif
	begin
		if (!rres_n)
		begin
			r_ptr	<= {ASIZE+1 {1'b0}};
			rack	<= 1'b0;
		end
		else
		begin
			if ((sync_wreq ^ rack))
			begin
				r_ptr	<= internal_reg;
				rack	<= ~rack;
			end
		end
	end

	//write side which sets the new value to be synchronized
	`ifdef ASYNC_RES
	always @(posedge wclk or negedge wres_n) `else
	always @(posedge wclk ) `endif
	begin
		if (!wres_n)
		begin
			internal_reg	<= {ASIZE+1 {1'b0}};
			wreq			<= 1'b0;
		end
		else
		begin
			if (!(sync_rack ^ wreq))
			begin
				internal_reg	<= w_ptr;
				wreq			<= ~wreq;
			end
		end
	end
endmodule

`default_nettype wire
