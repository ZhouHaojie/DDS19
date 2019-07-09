


## Prepare Timign uncertainty and period
######################

# Period 1ns
set     _period   2.0
set _SETUP_SKEW 0.150; 
set _HOLD_SKEW 0.05;

## Create Clock from top level clk port
######################
create_clock -name clk -period $_period [get_port  PAD_CLK]
 
## Generates slow clock
# 
create_generated_clock -add -name clk_slow  -master_clock clk -source [get_port  PAD_CLK] -divide_by 4  [get_pins pin:minisystem_top/clk_div_sr_reg[3]/q] -comment "Slow clock for logic behind FIFO" 

## Set Clock uncertainty: overclocking because we don't know how the physical constraints will look like
######################

set_clock_uncertainty $_SETUP_SKEW -setup clk
set_clock_uncertainty $_HOLD_SKEW  -hold  clk

set_clock_uncertainty $_SETUP_SKEW -setup clk_slow
set_clock_uncertainty $_HOLD_SKEW  -hold  clk_slow

##  Reset false path
##############
set_false_path -through PAD_RESN

## IO Delays
###########



## Common defined in % of the clock
## Those variables define from 0.0 (0%) to 1.0 (100%) the clock period part that counts as I/O delay
set _INPUT_DELAY  0.45
set _OUTPUT_DELAY 0.60


set realDelay [expr $_period*$_INPUT_DELAY]
set_input_delay -clock clk $realDelay [remove_from_collection [all_inputs] [concat PAD_CLK PAD_RESN] ]

set realDelay [expr $_period*$_OUTPUT_DELAY]
set_output_delay -clock clk $realDelay [all_outputs]


## Input Drive
#set_driving_cell -lib_cell STN_BUF_8 [all_inputs]

## output cap
set _OUTPUT_CAP 0.15;

set_load -pin_load $_OUTPUT_CAP [all_outputs]
