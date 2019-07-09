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

module full_logic #(
		parameter ASIZE				= 4,
		parameter HANDSHAKE			= 0,
		parameter ALMOST_FULL_THRES	= 2
	) (
		input wire				winc, wclk, wrst_n,
		input wire [ASIZE:0]	wq2_rptr,
		output reg				wfull,
		output reg				walmost_full,
		output reg [ASIZE:0]	wptr,
		output wire [ASIZE-1:0]	waddr
	);

	reg [ASIZE:0]	wbin;

	wire [ASIZE:0]	wbin_next;
	wire			wfull_w;

	genvar			j;

	assign waddr		= wbin[ASIZE-1:0];
	// calculate next write pointer
	assign wbin_next	= (winc && !wfull) ? (wbin + 1'b1) : wbin;

	generate
		if (ALMOST_FULL_THRES != 0)
		begin: almost_full_gen
			wire [ASIZE:0]	walmost_full_val;
			wire [ASIZE:0]	conv_rptr_w;
			wire			walmost_full_w;

			for (j=0; j <= ASIZE; j=j+1)
			begin: convert_gen
				// no convertion necessary if HANDSHAKE is set, otherwise convert gray to binary
				if (HANDSHAKE)
					assign conv_rptr_w[j] = wq2_rptr[j];
				else
					assign conv_rptr_w[j] = ^(wq2_rptr >> j);	// this can be pipelined if timing is tight
			end

			// add almost full threshold to write pointer
			assign walmost_full_val	= wbin_next + ALMOST_FULL_THRES[ASIZE:0];	// this can be pipelined if timing is tight
			// calculate next almost full signal, if both pointer are in the same round, the WP must be larger, otherwise smaller then the RP
			assign walmost_full_w	= ((walmost_full_val[(ASIZE-1):0] >= conv_rptr_w[(ASIZE-1):0]) && (conv_rptr_w[ASIZE] ^ walmost_full_val[ASIZE])) ||
										((walmost_full_val[(ASIZE-1):0] <= conv_rptr_w[(ASIZE-1):0]) && !(conv_rptr_w[ASIZE] ^ walmost_full_val[ASIZE]));

			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
			begin
				if (!wrst_n)
					walmost_full <= 1'b0;
				else
					walmost_full <= walmost_full_w || wfull_w;
			end
		end
		else
		begin: no_almost_full_gen
			// set almost full to static 0
			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
      begin
        if (!wrst_n)
				  walmost_full <= 1'b0;
        else
          walmost_full <= 1'b0;
      end
		end

		if (HANDSHAKE)
		begin: full_handshake_gen
			// calculate full signal according to Cummings
			assign wfull_w	= !(|(wq2_rptr[(ASIZE-1):0] ^ wbin_next[(ASIZE-1):0])) && (wq2_rptr[(ASIZE)] ^ wbin_next[(ASIZE)]);

			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
			begin
				if (!wrst_n)
					{wbin, wptr} <= {2*(ASIZE+1) {1'b0}};
				else
					{wbin, wptr} <= {wbin_next, wbin_next};
			end
		end
		else
		begin: full_direct_sync_gen
			wire [ASIZE:0]	wgray_next;
			// convert binary WP to gray
			assign wgray_next		= (wbin_next>>1) ^ wbin_next;
			// calculate full signal according to Cummings
			assign wfull_w			= ~(|(wgray_next ^ {~wq2_rptr[ASIZE:ASIZE-1], wq2_rptr[ASIZE-2:0]}));

			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
			begin
				if (!wrst_n)
					{wbin, wptr} <= {2*(ASIZE+1) {1'b0}};
				else
					{wbin, wptr} <= {wbin_next, wgray_next};
			end
		end
	endgenerate

	`ifdef ASYNC_RES
	always @(posedge wclk or negedge wrst_n) `else
	always @(posedge wclk) `endif
	begin
		if (!wrst_n)
			wfull <= 1'b0;
		else
			wfull <= wfull_w;
	end

`ifdef CAG_ASSERTIONS
	final
	begin
		write_pointer_not_zero_assert:	assert (wptr == wq2_rptr);
		full_set_assert:				assert (!wfull);
		almost_full_set_assert:			assert (!walmost_full);
	end
`endif

endmodule

`default_nettype wire
