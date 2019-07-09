module counter_tb;
reg reset_tb;
reg ena_tb;
reg reinit_tb;
reg clr_overflow_tb;
reg clk_tb;

reg clk_sr_tb;
reg reset_sr_tb;
reg ena_sr_tb;

parameter WIDTH_tb = 8;
wire overflow_tb;
wire overflow_err_tb;
wire [WIDTH_tb-1 : 0] value_tb;

wire [WIDTH_tb-1 : 0] value_sr_tb;

counter #(.WIDTH(WIDTH_tb)) u_counter(
  .clk(clk_tb),
  .reset(reset_tb),
  .ena(ena_tb),
  .reinit(reinit_tb),
  .clr_overflow(clr_overflow_tb),
  .value(value_tb),
  .overflow(overflow_tb),
  .overflow_err(overflow_err_tb),
  .clk_sr(clk_sr_tb),
  .reset_sr(reset_sr_tb),
  .ena_sr(ena_sr_tb),
  .value_sr(value_sr_tb)
);

always 
begin
  #10 clk_tb <= ~clk_tb;
end

initial
begin
  clk_tb = 1;
  ena_tb = 1;
  reset_tb = 1; 
  reinit_tb = 1;
  clr_overflow_tb = 0;
  #200 reset_tb = 0;
  #200 reinit_tb = 0;
  #200 ena_tb = 0;
  #200 ena_tb = 1;
  #1000 $display("Finished...");
  $finish();
end 

always
begin 
  #20 clk_sr_tb <= ~clk_sr_tb;
end 

initial 
begin 
  clk_sr_tb = 1;
  ena_sr_tb = 1;
  reset_sr_tb = 1;
  #200 reset_sr_tb = 0;
  #200 ena_sr_tb = 0;
  #200 ena_sr_tb = 1;
  #1000 $finish();
end 

endmodule
