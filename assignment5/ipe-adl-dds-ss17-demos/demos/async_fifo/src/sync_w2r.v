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

module sync_w2r #(
		parameter ASIZE = 4
	) (
		input wire				rclk, rrst_n,
		input wire [ASIZE:0]	wptr,
		output wire [ASIZE:0]	rq2_wptr
	);

`ifndef ASIC
	(* ASYNC_REG="TRUE", SHIFT_EXTRACT="NO", HBLKNM="rq1_wptr"*)   reg [ASIZE:0] rq1_wptr;
	(* ASYNC_REG="TRUE", SHIFT_EXTRACT="NO", HBLKNM="rq1_wptr_r"*) reg [ASIZE:0] rq1_wptr_r;
`else
  reg [ASIZE:0] rq1_wptr;
  reg [ASIZE:0] rq1_wptr_r;
`endif

	assign rq2_wptr = rq1_wptr_r;

	`ifdef ASYNC_RES
	always @( posedge rclk or negedge rrst_n) `else
	always @( posedge rclk ) `endif
	begin
		if (!rrst_n)
			{rq1_wptr_r, rq1_wptr} <= {2*(ASIZE+1) {1'b0}};
		else
			{rq1_wptr_r, rq1_wptr} <= {rq1_wptr, wptr};
	end
endmodule

`default_nettype wire
