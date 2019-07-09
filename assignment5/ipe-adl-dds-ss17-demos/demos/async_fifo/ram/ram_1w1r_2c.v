/****************************************************************************
 * ram_1w1r_2c.v
 ****************************************************************************/

/**
 * Module: ram_1w1r_2c
 * 
 * TODO: Add module documentation
 */
module ram_512x32  (
		
		input wire clk_a,
		input wire wen_a,
		input wire [8:0]  addr_a,
		input wire [31:0] wdata_a,

		input wire clk_b,
		input wire ren_b,
		input wire  [8:0] addr_b,
		output wire [31:0] rdata_b,
	
		// SEC/DED for single error/double error detection (ECC)
		// Not used, always return 0
		output wire sec,
		output wire ded
		
		
		);
	
	// IO
	//----------
	assign sec = 0;
	assign ded = 0;
	
	
	// RAM Instance
	//-----------------
	
	SJKA65_512X32X1CM4 RAM512x32 (
		
			// System
			.CKA(clk_a),
			.CKB(clk_b),
			.WEAN(!wen_a),
			.WEBN(1'b1),
			.CSAN(!wen_a),
			.CSBN(!ren_b),
			
			
			// Generated
			.DOA0(),
			.DOA1(),
			.DOA2(),
			.DOA3(),
			.DOA4(),
			.DOA5(),
			.DOA6(),
			.DOA7(),
			.DOA8(),
			.DOA9(),
			.DOA10(),
			.DOA11(),
			.DOA12(),
			.DOA13(),
			.DOA14(),
			.DOA15(),
			.DOA16(),
			.DOA17(),
			.DOA18(),
			.DOA19(),
			.DOA20(),
			.DOA21(),
			.DOA22(),
			.DOA23(),
			.DOA24(),
			.DOA25(),
			.DOA26(),
			.DOA27(),
			.DOA28(),
			.DOA29(),
			.DOA30(),
			.DOA31(),
			.DIA0(wdata_a[0]),
			.DIA1(wdata_a[1]),
			.DIA2(wdata_a[2]),
			.DIA3(wdata_a[3]),
			.DIA4(wdata_a[4]),
			.DIA5(wdata_a[5]),
			.DIA6(wdata_a[6]),
			.DIA7(wdata_a[7]),
			.DIA8(wdata_a[8]),
			.DIA9(wdata_a[9]),
			.DIA10(wdata_a[10]),
			.DIA11(wdata_a[11]),
			.DIA12(wdata_a[12]),
			.DIA13(wdata_a[13]),
			.DIA14(wdata_a[14]),
			.DIA15(wdata_a[15]),
			.DIA16(wdata_a[16]),
			.DIA17(wdata_a[17]),
			.DIA18(wdata_a[18]),
			.DIA19(wdata_a[19]),
			.DIA20(wdata_a[20]),
			.DIA21(wdata_a[21]),
			.DIA22(wdata_a[22]),
			.DIA23(wdata_a[23]),
			.DIA24(wdata_a[24]),
			.DIA25(wdata_a[25]),
			.DIA26(wdata_a[26]),
			.DIA27(wdata_a[27]),
			.DIA28(wdata_a[28]),
			.DIA29(wdata_a[29]),
			.DIA30(wdata_a[30]),
			.DIA31(wdata_a[31]),
			.A0(addr_a[0]),
			.A1(addr_a[1]),
			.A2(addr_a[2]),
			.A3(addr_a[3]),
			.A4(addr_a[4]),
			.A5(addr_a[5]),
			.A6(addr_a[6]),
			.A7(addr_a[7]),
			.A8(addr_a[8]),
			.DOB0(rdata_b[0]),
			.DOB1(rdata_b[1]),
			.DOB2(rdata_b[2]),
			.DOB3(rdata_b[3]),
			.DOB4(rdata_b[4]),
			.DOB5(rdata_b[5]),
			.DOB6(rdata_b[6]),
			.DOB7(rdata_b[7]),
			.DOB8(rdata_b[8]),
			.DOB9(rdata_b[9]),
			.DOB10(rdata_b[10]),
			.DOB11(rdata_b[11]),
			.DOB12(rdata_b[12]),
			.DOB13(rdata_b[13]),
			.DOB14(rdata_b[14]),
			.DOB15(rdata_b[15]),
			.DOB16(rdata_b[16]),
			.DOB17(rdata_b[17]),
			.DOB18(rdata_b[18]),
			.DOB19(rdata_b[19]),
			.DOB20(rdata_b[20]),
			.DOB21(rdata_b[21]),
			.DOB22(rdata_b[22]),
			.DOB23(rdata_b[23]),
			.DOB24(rdata_b[24]),
			.DOB25(rdata_b[25]),
			.DOB26(rdata_b[26]),
			.DOB27(rdata_b[27]),
			.DOB28(rdata_b[28]),
			.DOB29(rdata_b[29]),
			.DOB30(rdata_b[30]),
			.DOB31(rdata_b[31]),
			.DIB0(),
			.DIB1(),
			.DIB2(),
			.DIB3(),
			.DIB4(),
			.DIB5(),
			.DIB6(),
			.DIB7(),
			.DIB8(),
			.DIB9(),
			.DIB10(),
			.DIB11(),
			.DIB12(),
			.DIB13(),
			.DIB14(),
			.DIB15(),
			.DIB16(),
			.DIB17(),
			.DIB18(),
			.DIB19(),
			.DIB20(),
			.DIB21(),
			.DIB22(),
			.DIB23(),
			.DIB24(),
			.DIB25(),
			.DIB26(),
			.DIB27(),
			.DIB28(),
			.DIB29(),
			.DIB30(),
			.DIB31(),
			.B0(addr_b[0]),
			.B1(addr_b[1]),
			.B2(addr_b[2]),
			.B3(addr_b[3]),
			.B4(addr_b[4]),
			.B5(addr_b[5]),
			.B6(addr_b[6]),
			.B7(addr_b[7]),
			.B8(addr_b[8])			
			
		);

endmodule


