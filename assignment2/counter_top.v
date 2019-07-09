module counter #(parameter WIDTH = 32)(
  input clk,
  input reset,
  input ena,
  input reinit,
  input clr_overflow,
  output reg [WIDTH-1 : 0] value,
  output wire overflow,
  output wire overflow_err,

  input clk_sr,
  input reset_sr,
  input ena_sr,
  output reg [WIDTH-1:0] value_sr
);

parameter RES = 2'b00, CNT = 2'b01, OVF = 2'b11, ERR = 2'b10;
reg [1:0] state;
wire max_cnt;

assign overflow = {state == OVF};
assign overflow_err = {state == ERR};
assign max_cnt = {value == {WIDTH{1'b1}}};


always@(posedge clk)
begin
  if(reset | reinit)
  begin
    state <= RES;
    value <= 'b0;

  end 
  else
  begin 
    case(state)

      RES: state <= CNT;

      CNT: 
      begin 
        if(ena)
        begin 
          value <= value + 1'b1;
        end 

        if(ena & max_cnt)
        begin 
          state <= OVF;
        end 

      end 

      OVF:
      begin 
        if(clr_overflow)
        begin 
          state <= CNT;
        end 

        else if(ena & max_cnt)
        begin 
          state <= ERR;
        end 
      end 

      ERR: state <= ERR;

    endcase
  end 

end 

// Johnson Counter
always@(clk_sr)
begin 
    if(reset_sr)
    begin 
      value_sr <= 'b0;
    end
    else if(ena_sr)
    begin 
      if(value_sr[0] == 0)
      begin 
        value_sr <= {1'b1, value_sr[WIDTH-1 : 1]};
      end
      else 
      begin 
        value_sr <= {1'b0, value_sr[WIDTH-1 : 1]};
      end
    end
end

endmodule
