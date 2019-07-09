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

module full_logic_two_threshold #(
		parameter ASIZE					= 4,
		parameter HANDSHAKE				= 0,
		parameter ALMOST_FULL_THRES		= 2,
		parameter ALMOST_FULL_THRES_2	= 2
	) (
		input wire				winc, wclk, wrst_n,
		input wire [ASIZE:0]	wq2_rptr,
		output reg				wfull,
		output reg				walmost_full,
		output reg				walmost_full_2,
		output reg [ASIZE:0]	wptr,
		output wire [ASIZE-1:0]	waddr
	);

	reg [ASIZE:0]	wbin;

	wire [ASIZE:0]	wbin_next;
	wire			wfull_w;

	genvar			j;
	genvar			k;

	assign waddr		= wbin[ASIZE-1:0];
	// calculate next write pointer
	assign wbin_next	= (winc && !wfull) ? (wbin + 1'b1) : wbin;

	generate
		if (ALMOST_FULL_THRES != 0)
		begin: almost_full_one
			wire [ASIZE:0]	walmost_full_val;
			wire [ASIZE:0]	conv_rptr_w;
			wire			walmost_full_w;

			for (j=0; j <= ASIZE; j=j+1)
			begin: convert_gen_one
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
					walmost_full	<= 1'b0;
				else
					walmost_full	<= walmost_full_w || wfull_w;
			end
		end
		else
		begin: no_almost_full_one
			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
				walmost_full		<= 1'b0;
		end

		if (ALMOST_FULL_THRES_2 != 0)
		begin: almost_full_two
			wire [ASIZE:0]	walmost_full_val_th2;
			wire [ASIZE:0]	conv_rptr_w_th2;
			wire			walmost_full_w_th2;

			for (k=0; k <= ASIZE; k=k+1)
			begin: gen11
				if (HANDSHAKE)
					assign conv_rptr_w_th2[k] = wq2_rptr[k];
				else
					assign conv_rptr_w_th2[k] = ^(wq2_rptr >> k); //this can be pipelined if timing is tight
			end

			// add almost full threshold to write pointer
			assign walmost_full_val_th2	= wbin_next + ALMOST_FULL_THRES_2[ASIZE:0]; //this can be pipelined if timing is tight
			// calculate next almost full signal, if both pointer are in the same round, the WP must be larger, otherwise smaller then the RP
			assign walmost_full_w_th2	= ((walmost_full_val_th2[(ASIZE-1):0] >= conv_rptr_w_th2[(ASIZE-1):0]) && (conv_rptr_w_th2[ASIZE] ^ walmost_full_val_th2[ASIZE])) ||
										((walmost_full_val_th2[(ASIZE-1):0] <= conv_rptr_w_th2[(ASIZE-1):0]) && !(conv_rptr_w_th2[ASIZE] ^ walmost_full_val_th2[ASIZE]));

			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
			begin
				if (!wrst_n)
					walmost_full_2	<= 1'b0;
				else
					walmost_full_2	<= walmost_full_w_th2 || wfull_w;
			end
		end
		else
		begin: no_almost_full_two
			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
				walmost_full_2		<= 1'b0;
		end

		if (HANDSHAKE)
		begin: handshake_gen
			// calculate next full signal
			assign wfull_w	= !(|(wq2_rptr[(ASIZE-1):0] ^ wbin_next[(ASIZE-1):0])) && (wq2_rptr[(ASIZE)] ^ wbin_next[(ASIZE)]);

			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
			begin
				if (!wrst_n)
					{wbin, wptr}	<= {2*(ASIZE+1) {1'b0}};
				else
					{wbin, wptr}	<= {wbin_next, wbin_next};
			end
		end
		else
		begin: direct_sync_gen
			wire [ASIZE:0]	wgray_next;

			// convert WP to gray
			assign wgray_next	= (wbin_next>>1) ^ wbin_next;
			// calculate next full signal
			assign wfull_w		= ~(|(wgray_next ^ {~wq2_rptr[ASIZE:ASIZE-1], wq2_rptr[ASIZE-2:0]}));

			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
			begin
				if (!wrst_n)
					{wbin, wptr}	<= {2*(ASIZE+1) {1'b0}};
				else
					{wbin, wptr}	<= {wbin_next, wgray_next};
			end
		end
	endgenerate

	`ifdef ASYNC_RES
	always @(posedge wclk or negedge wrst_n) `else
	always @(posedge wclk) `endif
	begin
		if (!wrst_n)
			wfull					<= 1'b0;
		else
			wfull					<= wfull_w;
	end

`ifdef CAG_ASSERTIONS
	final
	begin
		write_pointer_not_zero_assert:	assert (wptr == wq2_rptr);
		full_set_assert:				assert (!wfull);
		almost_full_set_assert:			assert (!walmost_full);
		almost_full_2_set_assert:		assert (!walmost_full_2);
	end
`endif

endmodule

`default_nettype wire
