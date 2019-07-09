
// Generated by Cadence Genus(TM) Synthesis Solution 16.13-s036_1
// Generated on: Jul  8 2019 21:56:17 CEST (Jul  8 2019 19:56:17 UTC)

// Verification Directory fv/counter 

module add_unsigned(A, B, Z);
  input [7:0] A;
  input B;
  output [7:0] Z;
  wire [7:0] A;
  wire B;
  wire [7:0] Z;
  wire n_19, n_30, n_33, n_35, n_39, n_41, n_45, n_51;
  wire n_52, n_54, n_55, n_57, n_61, n_68, n_70, n_71;
  wire n_72, n_73, n_75, n_80, n_83, n_87, n_89, n_92;
  wire n_93;
  xor g1 (Z[0], A[0], B);
  nand g2 (n_19, A[0], B);
  nand g21 (n_33, n_30, A[1]);
  nor g26 (n_55, n_39, n_35);
  nor g30 (n_61, n_45, n_41);
  nand g36 (n_54, n_52, A[2]);
  nand g38 (n_57, n_55, n_52);
  nand g44 (n_72, n_61, A[6]);
  nand g51 (n_70, n_68, A[4]);
  nand g53 (n_71, n_61, n_68);
  not g55 (n_73, n_72);
  nand g56 (n_75, n_68, n_73);
  xnor g62 (Z[1], n_30, n_80);
  xnor g64 (Z[2], n_52, n_39);
  xnor g67 (Z[3], n_83, n_35);
  xnor g69 (Z[4], n_68, n_45);
  xnor g72 (Z[5], n_87, n_41);
  xnor g74 (Z[6], n_89, n_51);
  xnor g77 (Z[7], n_92, n_93);
  not g80 (n_39, A[2]);
  not g81 (n_35, A[3]);
  not g82 (n_45, A[4]);
  not g83 (n_41, A[5]);
  not g84 (n_51, A[6]);
  not g86 (n_30, n_19);
  not g87 (n_80, A[1]);
  not g88 (n_93, A[7]);
  not g89 (n_52, n_33);
  not g90 (n_83, n_54);
  not g91 (n_68, n_57);
  not g92 (n_87, n_70);
  not g93 (n_89, n_71);
  not g94 (n_92, n_75);
endmodule

module bmux(ctl, in_0, in_1, z);
  input ctl, in_0, in_1;
  output z;
  wire ctl, in_0, in_1;
  wire z;
  CDN_bmux2 g1(.sel0 (ctl), .data0 (in_0), .data1 (in_1), .z (z));
endmodule

module bmux_7(ctl, in_0, in_1, z);
  input ctl;
  input [7:0] in_0, in_1;
  output [7:0] z;
  wire ctl;
  wire [7:0] in_0, in_1;
  wire [7:0] z;
  CDN_bmux2 g1(.sel0 (ctl), .data0 (in_0[7]), .data1 (in_1[7]), .z
       (z[7]));
  CDN_bmux2 g2(.sel0 (ctl), .data0 (in_0[6]), .data1 (in_1[6]), .z
       (z[6]));
  CDN_bmux2 g3(.sel0 (ctl), .data0 (in_0[5]), .data1 (in_1[5]), .z
       (z[5]));
  CDN_bmux2 g4(.sel0 (ctl), .data0 (in_0[4]), .data1 (in_1[4]), .z
       (z[4]));
  CDN_bmux2 g5(.sel0 (ctl), .data0 (in_0[3]), .data1 (in_1[3]), .z
       (z[3]));
  CDN_bmux2 g6(.sel0 (ctl), .data0 (in_0[2]), .data1 (in_1[2]), .z
       (z[2]));
  CDN_bmux2 g7(.sel0 (ctl), .data0 (in_0[1]), .data1 (in_1[1]), .z
       (z[1]));
  CDN_bmux2 g8(.sel0 (ctl), .data0 (in_0[0]), .data1 (in_1[0]), .z
       (z[0]));
endmodule

module bmux_9(ctl, in_0, in_1, z);
  input ctl;
  input [1:0] in_0, in_1;
  output [1:0] z;
  wire ctl;
  wire [1:0] in_0, in_1;
  wire [1:0] z;
  CDN_bmux2 g1(.sel0 (ctl), .data0 (in_0[1]), .data1 (in_1[1]), .z
       (z[1]));
  CDN_bmux2 g2(.sel0 (ctl), .data0 (in_0[0]), .data1 (in_1[0]), .z
       (z[0]));
endmodule

module bmux_10(ctl, in_0, in_1, in_2, in_3, z);
  input [1:0] ctl, in_0, in_1, in_2, in_3;
  output [1:0] z;
  wire [1:0] ctl, in_0, in_1, in_2, in_3;
  wire [1:0] z;
  CDN_bmux4 g1(.sel0 (ctl[0]), .data0 (in_0[1]), .data1 (in_1[1]),
       .sel1 (ctl[1]), .data2 (in_2[1]), .data3 (in_3[1]), .z (z[1]));
  CDN_bmux4 g2(.sel0 (ctl[0]), .data0 (in_0[0]), .data1 (in_1[0]),
       .sel1 (ctl[1]), .data2 (in_2[0]), .data3 (in_3[0]), .z (z[0]));
endmodule

module counter(clk, reset, ena, reinit, clr_overflow, value, overflow,
     overflow_err, clk_sr, reset_sr, ena_sr, value_sr);
  input clk, reset, ena, reinit, clr_overflow, clk_sr, reset_sr, ena_sr;
  output [7:0] value, value_sr;
  output overflow, overflow_err;
  wire clk, reset, ena, reinit, clr_overflow, clk_sr, reset_sr, ena_sr;
  wire [7:0] value, value_sr;
  wire overflow, overflow_err;
  wire [1:0] state;
  wire UNCONNECTED, UNCONNECTED0, UNCONNECTED1, UNCONNECTED2,
       UNCONNECTED3, UNCONNECTED4, UNCONNECTED5, UNCONNECTED6;
  wire UNCONNECTED7, UNCONNECTED8, n_47, n_55, n_56, n_58, n_59, n_60;
  wire n_61, n_62, n_63, n_64, n_65, n_66, n_69, n_70;
  wire n_71, n_72, n_75, n_77, n_78, n_80, n_81, n_82;
  wire n_83, n_84, n_88, n_89, n_90, n_91, n_92, n_93;
  wire n_94, n_95, n_96, n_97, n_98, n_99, n_113, n_114;
  wire n_115, n_116, n_117, n_118, n_177, n_180, n_181, n_182;
  wire n_183, n_184, n_185, n_186;
  add_unsigned add_44_26(.A (value), .B (1'b1), .Z ({n_65, n_64, n_63,
       n_62, n_61, n_60, n_59, n_58}));
  bmux mux_value_sr_83_22(.ctl (n_47), .in_0 (1'b0), .in_1 (1'b1), .z
       (n_55));
  bmux_7 mux_value_sr_77_8(.ctl (reset_sr), .in_0 ({n_55,
       value_sr[7:1]}), .in_1 (8'b00000000), .z ({n_99, n_98, n_97,
       n_96, n_95, n_94, n_93, n_91}));
  bmux_7 mux_value_28_12(.ctl (n_56), .in_0 ({n_65, n_64, n_63, n_62,
       n_61, n_60, n_59, n_58}), .in_1 (8'b00000000), .z
       ({UNCONNECTED6, UNCONNECTED5, UNCONNECTED4, UNCONNECTED3,
       UNCONNECTED2, UNCONNECTED1, UNCONNECTED0, UNCONNECTED}));
  bmux_9 mux_state_56_12(.ctl (clr_overflow), .in_0 (2'b10), .in_1
       (2'b01), .z ({n_70, n_69}));
  bmux_10 mux_state_36_10(.ctl (state), .in_0 (2'b01), .in_1 (2'b11),
       .in_2 (2'b10), .in_3 ({n_70, n_69}), .z ({n_72, n_71}));
  bmux_9 mux_state_28_12(.ctl (n_56), .in_0 ({n_72, n_71}), .in_1
       (2'b00), .z ({UNCONNECTED8, UNCONNECTED7}));
  or g1 (n_56, reset, reinit);
  not g7 (n_89, reset_sr);
  not g13 (n_80, clr_overflow);
  and g15 (n_77, ena, n_75);
  and g16 (n_78, n_66, n_75);
  and g18 (n_81, n_66, n_80);
  or g19 (n_82, n_81, clr_overflow);
  and g20 (n_84, n_82, n_83);
  and g23 (n_90, ena_sr, n_89);
  or g24 (n_92, n_90, reset_sr);
  nand g27 (n_115, n_113, n_114);
  nand g28 (n_116, state[0], n_114);
  nand g29 (n_117, state[0], state[1]);
  nand g30 (n_118, n_113, state[1]);
  not g32 (n_75, n_116);
  not g33 (n_83, n_117);
  not g35 (n_114, state[1]);
  not g36 (n_113, state[0]);
  CDN_flop \value_reg[0] (.clk (clk), .d (n_58), .sena (n_77), .aclr
       (1'b0), .apre (1'b0), .srl (n_56), .srd (1'b0), .q (value[0]));
  CDN_flop \value_reg[1] (.clk (clk), .d (n_59), .sena (n_77), .aclr
       (1'b0), .apre (1'b0), .srl (n_56), .srd (1'b0), .q (value[1]));
  CDN_flop \value_reg[2] (.clk (clk), .d (n_60), .sena (n_77), .aclr
       (1'b0), .apre (1'b0), .srl (n_56), .srd (1'b0), .q (value[2]));
  CDN_flop \value_reg[3] (.clk (clk), .d (n_61), .sena (n_77), .aclr
       (1'b0), .apre (1'b0), .srl (n_56), .srd (1'b0), .q (value[3]));
  CDN_flop \value_reg[4] (.clk (clk), .d (n_62), .sena (n_77), .aclr
       (1'b0), .apre (1'b0), .srl (n_56), .srd (1'b0), .q (value[4]));
  CDN_flop \value_reg[5] (.clk (clk), .d (n_63), .sena (n_77), .aclr
       (1'b0), .apre (1'b0), .srl (n_56), .srd (1'b0), .q (value[5]));
  CDN_flop \value_reg[6] (.clk (clk), .d (n_64), .sena (n_77), .aclr
       (1'b0), .apre (1'b0), .srl (n_56), .srd (1'b0), .q (value[6]));
  CDN_flop \value_reg[7] (.clk (clk), .d (n_65), .sena (n_77), .aclr
       (1'b0), .apre (1'b0), .srl (n_56), .srd (1'b0), .q (value[7]));
  CDN_flop \state_reg[0] (.clk (clk), .d (n_71), .sena (n_88), .aclr
       (1'b0), .apre (1'b0), .srl (n_56), .srd (1'b0), .q (state[0]));
  CDN_flop \state_reg[1] (.clk (clk), .d (n_72), .sena (n_88), .aclr
       (1'b0), .apre (1'b0), .srl (n_56), .srd (1'b0), .q (state[1]));
  CDN_latch \value_sr_reg[0] (.d (n_91), .ena (n_92), .aclr (1'b0),
       .apre (1'b0), .q (value_sr[0]));
  CDN_latch \value_sr_reg[1] (.d (n_93), .ena (n_92), .aclr (1'b0),
       .apre (1'b0), .q (value_sr[1]));
  CDN_latch \value_sr_reg[2] (.d (n_94), .ena (n_92), .aclr (1'b0),
       .apre (1'b0), .q (value_sr[2]));
  CDN_latch \value_sr_reg[3] (.d (n_95), .ena (n_92), .aclr (1'b0),
       .apre (1'b0), .q (value_sr[3]));
  CDN_latch \value_sr_reg[4] (.d (n_96), .ena (n_92), .aclr (1'b0),
       .apre (1'b0), .q (value_sr[4]));
  CDN_latch \value_sr_reg[5] (.d (n_97), .ena (n_92), .aclr (1'b0),
       .apre (1'b0), .q (value_sr[5]));
  CDN_latch \value_sr_reg[6] (.d (n_98), .ena (n_92), .aclr (1'b0),
       .apre (1'b0), .q (value_sr[6]));
  CDN_latch \value_sr_reg[7] (.d (n_99), .ena (n_92), .aclr (1'b0),
       .apre (1'b0), .q (value_sr[7]));
  nand g68 (n_177, state[1], state[0]);
  not g69 (overflow, n_177);
  nand g72 (n_180, state[1], n_113);
  not g73 (overflow_err, n_180);
  not g74 (n_47, value_sr[0]);
  or g75 (n_88, n_181, n_182, n_84, n_78);
  not g76 (n_181, n_118);
  not g77 (n_182, n_115);
  and g78 (n_183, ena, value[4], value[5]);
  and g79 (n_184, value[6], value[7]);
  and g80 (n_185, value[0], value[1]);
  and g81 (n_186, value[2], value[3]);
  and g82 (n_66, n_183, n_184, n_185, n_186);
endmodule

`ifdef RC_CDN_GENERIC_GATE
`else
module CDN_flop(clk, d, sena, aclr, apre, srl, srd, q);
  input clk, d, sena, aclr, apre, srl, srd;
  output q;
  wire clk, d, sena, aclr, apre, srl, srd;
  wire q;
  reg  qi;
  assign #1 q = qi;
  always 
    @(posedge clk or posedge apre or posedge aclr) 
      if (aclr) 
        qi <= 0;
      else if (apre) 
          qi <= 1;
        else if (srl) 
            qi <= srd;
          else begin
            if (sena) 
              qi <= d;
          end
  initial 
    qi <= 1'b0;
endmodule
`endif
`ifdef RC_CDN_GENERIC_GATE
`else
module CDN_latch(ena, d, aclr, apre, q);
  input ena, d, aclr, apre;
  output q;
  wire ena, d, aclr, apre;
  wire q;
  reg  qi;
  assign #1 q = qi;
  always 
    @(d or ena or apre or aclr) 
      if (aclr) 
        qi <= 0;
      else if (apre) 
          qi <= 1;
        else begin
          if (ena) 
            qi <= d;
        end
  initial 
    qi <= 1'b0;
endmodule
`endif
`ifdef RC_CDN_GENERIC_GATE
`else
`ifdef ONE_HOT_MUX
module CDN_bmux2(sel0, data0, data1, z);
  input sel0, data0, data1;
  output z;
  wire sel0, data0, data1;
  reg  z;
  always 
    @(sel0 or data0 or data1) 
      case ({sel0})
       1'b0: z = data0;
       1'b1: z = data1;
      endcase
endmodule
`else
module CDN_bmux2(sel0, data0, data1, z);
  input sel0, data0, data1;
  output z;
  wire sel0, data0, data1;
  wire z;
  wire inv_sel0, w_0, w_1;
  not i_0 (inv_sel0, sel0);
  and a_0 (w_0, inv_sel0, data0);
  and a_1 (w_1, sel0, data1);
  or org (z, w_0, w_1);
endmodule
`endif // ONE_HOT_MUX
`endif
`ifdef RC_CDN_GENERIC_GATE
`else
`ifdef ONE_HOT_MUX
module CDN_bmux4(sel0, data0, data1, sel1, data2, data3, z);
  input sel0, data0, data1, sel1, data2, data3;
  output z;
  wire sel0, data0, data1, sel1, data2, data3;
  reg  z;
  always 
    @(sel0 or sel1 or data0 or data1 or data2 or data3) 
      case ({sel0, sel1})
       2'b00: z = data0;
       2'b10: z = data1;
       2'b01: z = data2;
       2'b11: z = data3;
      endcase
endmodule
`else
module CDN_bmux4(sel0, data0, data1, sel1, data2, data3, z);
  input sel0, data0, data1, sel1, data2, data3;
  output z;
  wire sel0, data0, data1, sel1, data2, data3;
  wire z;
  wire inv_sel0, inv_sel1, w_0, w_1, w_2, w_3;
  not i_0 (inv_sel0, sel0);
  not i_1 (inv_sel1, sel1);
  and a_0 (w_0, inv_sel1, inv_sel0, data0);
  and a_1 (w_1, inv_sel1, sel0, data1);
  and a_2 (w_2, sel1, inv_sel0, data2);
  and a_3 (w_3, sel1, sel0, data3);
  or org (z, w_0, w_1, w_2, w_3);
endmodule
`endif // ONE_HOT_MUX
`endif