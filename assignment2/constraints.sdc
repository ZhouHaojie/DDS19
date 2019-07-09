## [get_port clock] is calling the command get_port which returns a pointer to an input 
## or output named "clock"
create_clock -name clk -period 2.000 [get_port clk]
create_clock -name clk_sr -period 2.000 [get_port clk_sr]

## add clock uncertainty
set_clock_uncertainty 0.2 -setup clk 
set_clock_uncertainty 0.1  -hold clk 

set_clock_uncertainty 0.2 -setup clk_sr
set_clock_uncertainty 0.1 -hold clk_sr

set_output_delay -clock clk 0.5 [get_ports clk]
set_output_delay -clock clk_sr 0.5 [get_ports clk_sr]

set_load -pin_load 0.2 [all_outputs]
