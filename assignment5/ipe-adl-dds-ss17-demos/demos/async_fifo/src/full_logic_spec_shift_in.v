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

module full_logic_spec_shift_in #(
		parameter ASIZE				= 4,
		parameter HANDSHAKE			= 0,
		parameter ALMOST_FULL_THRES	= 2,
		parameter I_KNOW_WHAT_I_DO	= 0	// This parameter is a timing improvement, which can cause data corruption if You are not cautious
	) (
		input wire				winc, wclk, wrst_n,
		input wire [ASIZE:0]	wq2_rptr,
		input wire				inc_wptr,
		input wire				dec_wptr,
		input wire [ASIZE:0]	inc_dec_value,
		output reg				walmost_full,
		output reg				wfull,
		output reg [ASIZE:0]	wptr,
		output wire [ASIZE-1:0]	waddr
	);

	reg [ASIZE:0]				wbin, wbin_next;
	reg [ASIZE:0]				wbin_tmp, wbin_tmp_next;

	wire						wfull_w;
	wire [ASIZE:0]				conv_rptr_w;

	genvar						j;

	// calculate next full value
	assign wfull_w	= ~(|(conv_rptr_w[(ASIZE-1):0] ^ wbin_tmp_next[(ASIZE-1):0])) & (conv_rptr_w[(ASIZE)] ^ wbin_tmp_next[(ASIZE)]);
	assign waddr	= wbin_tmp[ASIZE-1:0];

	generate
		for (j=0; j <= ASIZE; j=j+1)
		begin: convert_gen
			// if HANDSHAKE is set, do nothing, else convert from gray to binary
			if (HANDSHAKE)
				assign conv_rptr_w[j] = wq2_rptr[j];
			else
				assign conv_rptr_w[j] = ^(wq2_rptr >> j);	// this can be pipelined if timing is tight
		end

		if (ALMOST_FULL_THRES != 0)
		begin: almost_full_gen
			wire [ASIZE:0]	walmost_full_val;
			wire			walmost_full_w;

			// add almost full threshold to write pointer
			assign walmost_full_val	= wbin_tmp_next + ALMOST_FULL_THRES[ASIZE:0];	// this can be pipelined if timing is tight
			// calculate next almost full signal, if both pointer are in the same round, the WP must be larger, otherwise smaller then the RP
			assign walmost_full_w	= ((walmost_full_val[(ASIZE-1):0] >= conv_rptr_w[(ASIZE-1):0]) & (conv_rptr_w[(ASIZE)] ^ walmost_full_val[(ASIZE)])) |
										((walmost_full_val[(ASIZE-1):0] <= conv_rptr_w[(ASIZE-1):0]) & ~(conv_rptr_w[(ASIZE)] ^ walmost_full_val[(ASIZE)]));

			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
			begin
				if (!wrst_n)
					walmost_full <= 1'b0;
				else
					walmost_full <= walmost_full_w | wfull_w;
			end
		end
		else
		begin: no_almost_full_gen
			// set almost full to static 0
			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
				walmost_full <= 1'b0;
		end

		if (HANDSHAKE)
		begin: handshake_gen
			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
			begin
				if (!wrst_n)
					{wbin, wptr, wbin_tmp} <= {3*(ASIZE+1) {1'b0}};
				else
					{wbin, wptr, wbin_tmp} <= {wbin_next, wbin_next, wbin_tmp_next};
			end
		end
		else
		begin: direct_sync_gen
			wire [ASIZE:0]	wgray_next;

			// convert binary to gray code
			assign wgray_next		= (wbin_next>>1) ^ wbin_next;

			`ifdef ASYNC_RES
			always @(posedge wclk or negedge wrst_n) `else
			always @(posedge wclk) `endif
			begin
				if (!wrst_n)
					{wbin, wptr, wbin_tmp} <= {3*(ASIZE+1) {1'b0}};
				else
					{wbin, wptr, wbin_tmp} <= {wbin_next, wgray_next, wbin_tmp_next};
			end
		end

		if (I_KNOW_WHAT_I_DO == 1) // not checking for add_is_smaller, can cause data inconsistency
		begin: no_spec_check_gen
			always @( * )
			begin
				// increment commited pointer by value
				// this pointer is used for empty calculation
				case ({inc_wptr, dec_wptr})
					2'b10:		wbin_next = wbin + inc_dec_value;
					default:	wbin_next = wbin;
				endcase
			end

			always @( * )
			begin
				// increment/decrement speculative pointer by value
				// this pointer is used for writing and full calculation
				casez ({winc, dec_wptr, inc_wptr, wfull})
					4'b10?0:	wbin_tmp_next = wbin_tmp + 1'b1;
					4'b010?:	wbin_tmp_next = wbin_tmp - inc_dec_value;
					// these two cases are only necessary if simultaneous shift_in and dec shall be possible => possible data inconsistency
					// SIMULTANEOUS SHIFT_IN AND DEC IS CURRENTLY NOT ALLOWED
//					4'b1100:	wbin_tmp_next = wbin + 1;
					default:	wbin_tmp_next = wbin_tmp;
				endcase
			end
		end
		else
		begin: speck_check_gen
			wire	add_is_smaller;

			assign add_is_smaller	= (wbin_tmp - inc_dec_value) > wbin;

			always @( * )
			begin
				// increment commited pointer by value
				// this pointer is used for empty calculation
				casez ({inc_wptr, dec_wptr, winc, add_is_smaller})
					4'b10?1:	wbin_next = wbin + inc_dec_value;
					4'b1000:	wbin_next = wbin_tmp;
					4'b1010:	wbin_next = wbin_tmp + 1'b1;
					default:	wbin_next = wbin;
				endcase
			end

			always @( * )
			begin
				// increment/decrement speculative pointer by value
				// this pointer is used for writing and full calculation
				casez ({winc, dec_wptr, inc_wptr, wfull, add_is_smaller})
					5'b10?0?:	wbin_tmp_next = wbin_tmp + 1'b1;
					5'b010?1:	wbin_tmp_next = wbin_tmp - inc_dec_value;
					5'b010?0:	wbin_tmp_next = wbin;
					// these two cases are only necessary if simultaneous shift_in and dec shall be possible => possible data inconsistency
					// SIMULTANEOUS SHIFT_IN AND DEC IS CURRENTLY NOT ALLOWED
//					5'b11001:	wbin_tmp_next = (wbin_tmp + 1) - inc_dec_value;
//					5'b11000:	wbin_tmp_next = wbin + 1;
					default:	wbin_tmp_next = wbin_tmp;
				endcase
			end
		end
	endgenerate

	// register full signal
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
