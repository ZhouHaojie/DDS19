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

module empty_logic_spec_shift_out_1_inc #(
		parameter ASIZE		= 4,
		parameter HANDSHAKE	= 0
	) (
		input wire				rclk, rrst_n,
		input wire				rinc,
		input wire				inc_rptr,
		input wire				dec_rptr,
		input wire [ASIZE:0]	rq2_wptr,
		output reg				rempty,
		output reg [ASIZE:0]	rptr,
		output wire [ASIZE-1:0]	raddr
	);

	reg [ASIZE:0]	rbin, rbin_next;
	reg [ASIZE:0]	rbin_tmp, rbin_tmp_next;

	wire			no_spec_val;
	wire			rempty_val;

	// checking whether there is speculative data present or not
	assign no_spec_val		= ~(|(rbin_tmp ^ rbin));
	assign raddr			= rbin_tmp[ASIZE-1:0];

	generate
		if (HANDSHAKE)
		begin: handshake_gen
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
		case ({inc_rptr, no_spec_val})
			2'b10:		rbin_next = rbin + 1'b1;
			default:	rbin_next = rbin;
		endcase
	end

	// calculating the speculative read pointer based on shift out signal and decrement
	// this pointer is used for the empty generation, as well as the actual read operation
	always @( * )
	begin
		// SIMULTANEOUS SHIFT_IN AND DEC IS NOT ALLOWED!
		casez ({rinc, dec_rptr, rempty, no_spec_val})
			4'b1?0?:	rbin_tmp_next = rbin_tmp + 1'b1;
			4'b01?0:	rbin_tmp_next = rbin_tmp - 1'b1;
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
