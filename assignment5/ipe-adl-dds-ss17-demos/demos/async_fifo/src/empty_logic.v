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

module empty_logic #(
		parameter ASIZE		= 4,
		parameter HANDSHAKE	= 0,
		parameter ALMOST_EMPTY_THRES = 2
	) (
		input wire				rclk, rrst_n,
		input wire				rinc,
		input wire [ASIZE:0]	rq2_wptr,
		output reg				rempty,
		output reg				almost_rempty,
		output reg [ASIZE:0]	rptr,
		output wire [ASIZE-1:0]	raddr
	);

	reg [ASIZE:0]	rbin;

	wire [ASIZE:0]	rbin_next;
	wire			rempty_val;

	genvar			j;

	assign raddr		= rbin[ASIZE-1:0];
	assign rbin_next	= (rinc && !rempty) ? (rbin + 1'b1) : rbin;

	generate
		if (HANDSHAKE)
		begin: handshake_gen
			// calculating next empty value
			assign rempty_val	= ~(|(rbin_next ^ rq2_wptr));

			`ifdef ASYNC_RES
			always @(posedge rclk or negedge rrst_n) `else
			always @(posedge rclk) `endif
			begin
				if (!rrst_n)
					{rbin, rptr} <= {2*(ASIZE+1) {1'b0}};
				else
					{rbin, rptr} <= {rbin_next, rbin_next};
			end
		end
		else
		begin: direct_sync_gen
			wire [ASIZE:0]	rgraynext;

			// converting binary address to gray code
			assign rgraynext	= (rbin_next>>1) ^ rbin_next;
			// calculating empty value
			assign rempty_val	= ~(|(rgraynext ^ rq2_wptr));

			`ifdef ASYNC_RES
			always @(posedge rclk or negedge rrst_n) `else
			always @(posedge rclk) `endif
			begin
				if (!rrst_n)
					{rbin, rptr} <= {2*(ASIZE+1) {1'b0}};
				else
					{rbin, rptr} <= {rbin_next, rgraynext};
			end
		end

		// generating almost empty
		if (ALMOST_EMPTY_THRES != 0)
		begin: almost_full_gen
			wire [ASIZE:0]		almost_rempty_val;
			wire				almost_rempty_w;
			wire [ASIZE:0]		conv_wptr_w;

			for (j=0; j <= ASIZE; j=j+1)
			begin: convert_gray_gen
				// no converstion is necessary of HANDSHAKE is set, otherwise convert write pointer to binary
				if (HANDSHAKE)
					assign conv_wptr_w[j] = rq2_wptr[j];
				else
					assign conv_wptr_w[j] = ^(rq2_wptr >> j);	//this can be pipelined if timing is tight
			end

			// adding almost empty threshold to current read pointer
			assign almost_rempty_val	= rbin + ALMOST_EMPTY_THRES[ASIZE:0];
			// calculating the next almost empty value, if pointers are not in same round, the write pointer must be smaller, otherwise larger than the read pointer
			assign almost_rempty_w		= ((conv_wptr_w[(ASIZE-1):0] <= almost_rempty_val[(ASIZE-1):0]) && !(conv_wptr_w[ASIZE] ^ almost_rempty_val[ASIZE])) ||
											(conv_wptr_w[ASIZE-1:0] >= almost_rempty_val[ASIZE-1:0] && (conv_wptr_w[ASIZE] ^ almost_rempty_val[ASIZE]));

			`ifdef ASYNC_RES
			always @(posedge rclk or negedge rrst_n) `else
			always @(posedge rclk) `endif
			begin
				if (!rrst_n)
					almost_rempty <= 1'b1;
				else
					almost_rempty <= almost_rempty_w || rempty_val;
			end
		end
		else
		begin: no_almost_empty_gen
			// set almost empty to static one
			`ifdef ASYNC_RES
			always @(posedge rclk or negedge rrst_n) `else
			always @(posedge rclk) `endif
      begin
				if (!rrst_n) 
          almost_rempty <= 1'b1;
        else
          almost_rempty <= 1'b1;
      end
		end
	endgenerate

	`ifdef ASYNC_RES
	always @(posedge rclk or negedge rrst_n) `else
	always @(posedge rclk) `endif
	begin
		if (!rrst_n)
			rempty <= 1'b1;
		else
			rempty <= rempty_val;
	end

`ifdef CAG_ASSERTIONS
	final
	begin
		read_pointer_match_assert:		assert (rq2_wptr == rptr);
		rempty_not_set_assert:			assert (rempty);
		almost_rempty_not_set_assert:	assert (almost_rempty);
	end
`endif
endmodule

`default_nettype wire
