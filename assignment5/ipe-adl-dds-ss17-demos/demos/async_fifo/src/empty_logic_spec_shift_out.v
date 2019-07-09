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

module empty_logic_spec_shift_out #(
		parameter ASIZE		= 4,
		parameter HANDSHAKE	= 0
	) (
		input wire				rclk, rrst_n,
		input wire				rinc,
		input wire				inc_rptr,
		input wire				dec_rptr,
		input wire [ASIZE:0]	inc_dec_value,
		input wire [ASIZE:0]	rq2_wptr,
		output reg				rempty,
		output reg [ASIZE:0]	rptr,
		output wire [ASIZE-1:0]	raddr
	);

	reg [ASIZE:0]	rbin, rbin_next;
	reg [ASIZE:0]	rbin_tmp, rbin_tmp_next;

	wire			add_is_smaller;
	wire			rempty_val;

	// checking whether the increment value would cause the pointers to overtake each other, could be removed if timing is thight
	assign add_is_smaller	= (rbin_tmp - inc_dec_value) > rbin;
	assign raddr			= rbin_tmp[ASIZE-1:0];

	generate
		if (HANDSHAKE)
		begin: handshake_gen
			// calculating next empty value
			assign rempty_val	= ~(|(rbin_tmp_next ^ rq2_wptr));

			`ifdef ASYNC_RES
			always @(posedge rclk or negedge rrst_n) `else
			always @(posedge rclk) `endif
			begin
				if (!rrst_n)
					{rbin, rptr, rbin_tmp} <= {3*(ASIZE+1) {1'b0}};
				else
					{rbin, rptr, rbin_tmp} <= {rbin_next, rbin_next, rbin_tmp_next};
			end
		end
		else
		begin: direct_sync_gen
			wire [ASIZE:0]	rgray_next;
			wire [ASIZE:0]	rtmp_gray_next;

			// converting binary address to gray code
			assign rgray_next		= (rbin_next>>1) ^ rbin_next;
			// converting speculative pointer to gray code
			assign rtmp_gray_next	= (rbin_tmp_next>>1) ^ rbin_tmp_next;
			// calculating empty value
			assign rempty_val		= ~(|(rtmp_gray_next ^ rq2_wptr));

			`ifdef ASYNC_RES
			always @(posedge rclk or negedge rrst_n) `else
			always @(posedge rclk) `endif
			begin
				if (!rrst_n)
					{rbin, rptr, rbin_tmp} <= {3*(ASIZE+1) {1'b0}};
				else
					{rbin, rptr, rbin_tmp} <= {rbin_next, rgray_next, rbin_tmp_next};
			end
		end
	endgenerate

	// calculating the commited read pointer based on increment and decrement signals
	// this pointer is used for the full generation on the other side
	// ATTENTION: GLITCHES IN THE SYNC PROCESS MAY OCCUR IF HANDSHAKE OPTION IS NOT ACTIVATED!!!
	always @( * )
	begin
		casez ({inc_rptr, dec_rptr, rinc, add_is_smaller})
			4'b10?1:	rbin_next = rbin + inc_dec_value;
			4'b1000:	rbin_next = rbin_tmp;
			4'b1010:	rbin_next = rbin_tmp + 1'b1;
			default:	rbin_next = rbin;
		endcase
	end

	// calculating the speculative read pointer based on shift out signal and decrement
	// this pointer is used for the empty generation, as well as the actual read operation
	always @( * )
	begin
		casez ({rinc, dec_rptr, inc_rptr, rempty, add_is_smaller})
			5'b10?0?:	rbin_tmp_next = rbin_tmp + 1'b1;
			5'b010?1:	rbin_tmp_next = rbin_tmp - inc_dec_value; //1'b1;
			5'b010?0:	rbin_tmp_next = rbin;
			// these two cases are only necessary if simultaneous shift_in and dec shall be possible => possible data inconsistency
			// SIMULTANEOUS SHIFT_IN AND DEC IS CURRENTLY NOT ALLOWED
//			5'b11001:	wbin_tmp_next = (wbin_tmp + 1) - inc_dec_value;
//			5'b11000:	wbin_tmp_next = wbin + 1;
			default:	rbin_tmp_next = rbin_tmp;
		endcase
	end

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
		read_pointer_match_assert:	assert (rq2_wptr == rptr);
		rempty_not_set_assert:		assert (rempty);
	end
`endif

endmodule

`default_nettype wire
