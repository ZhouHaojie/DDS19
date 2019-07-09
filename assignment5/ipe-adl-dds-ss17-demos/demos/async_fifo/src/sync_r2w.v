
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

module sync_r2w #(
		parameter ASIZE = 4
	) (
		input wire				wclk, wrst_n,
		input wire [ASIZE:0]	rptr,
		output wire [ASIZE:0]	wq2_rptr
	);

`ifndef ASIC
	(* ASYNC_REG="TRUE", SHIFT_EXTRACT="NO", HBLKNM="wq1_rptr"*)   reg [ASIZE:0] wq1_rptr;
	(* ASYNC_REG="TRUE", SHIFT_EXTRACT="NO", HBLKNM="wq1_rptr_r"*) reg [ASIZE:0] wq1_rptr_r;
`else
  reg [ASIZE:0] wq1_rptr;
  reg [ASIZE:0] wq1_rptr_r;
`endif

	assign wq2_rptr = wq1_rptr_r;

	`ifdef ASYNC_RES
	always @( posedge wclk or negedge wrst_n) `else
	always @( posedge wclk ) `endif
	begin
		if (!wrst_n)
			{wq1_rptr_r, wq1_rptr} <= {2*(ASIZE+1) {1'b0}};
		else
			{wq1_rptr_r, wq1_rptr} <= {wq1_rptr, rptr};
	end
endmodule

`default_nettype wire
