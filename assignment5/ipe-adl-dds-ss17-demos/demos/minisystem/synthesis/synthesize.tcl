set BASE [file dirname [file normalize [info script]]]/../
set WORK $BASE/run 


## Load Libraries
######################

## Worst case
set_db library [list  \
    $env(UMC_HOME)/65nm-stdcells/synopsys/uk65lscllmvbbr_108c125_wc.lib \
    $env(UMC_HOME)/rams/512x32/SJKA65_512X32X1CM4/SJKA65_512X32X1CM4_ss1p08v125c.lib \
    $env(UMC_HOME)/65nm-pads/synopsys/u065gioll18gpir_wc.lib
]



## Load design
####################
read_hdl -sv -define ASIC [list $BASE/../async_fifo/ram/ram_1w1r_2c.v \
			$BASE/../async_fifo/src/fifo_reg.v \
			$BASE/../async_fifo/src/async_standard_fifo.v \
			$BASE/../async_fifo/src/sync_r2w.v \
			$BASE/../async_fifo/src/sync_w2r.v \
			$BASE/../async_fifo/src/sync_w2r_hs.v \
			$BASE/../async_fifo/src/empty_logic.v \
			$BASE/../async_fifo/src/full_logic.v \
			$BASE/../async_fifo/src/empty_logic_spec_shift_out.v \
			$BASE/../async_fifo/src/empty_logic_spec_shift_out_1_inc.v \
			$BASE/../async_fifo/src/full_logic_spec_shift_in.v \
			$BASE/../async_fifo/src/full_logic_spec_shift_in_1_inc.v \
			$BASE/../async_fifo/src/async_fifo.v \
			$BASE/minisystem_top.v $BASE/link.v $BASE/igress_fsm.v $BASE/egress_fsm.v $BASE/counter_match.v ] 



## Elaborate
###################"
elaborate



## Load constraints
#################
read_sdc $BASE/synthesis/constraints.sdc


##  Create Cost groups
##########################

#set all_regs [find / -instance instances_seq/*]
set all_regs [all des seqs -clock clk]
define_cost_group -name C2C
path_group -from $all_regs -to $all_regs -group C2C -name C2C

set inputs [all des inps -clock clk]
define_cost_group -name I2C 
path_group -from $inputs -to $all_regs -group I2C -name I2C

set outputs [all des outs -clock clk]
define_cost_group -name C2O 
path_group -from $all_regs -to $outputs -group C2O -name C2O

if {[llength $inputs]>0 && [llength $outputs]>0} {
	define_cost_group -name I2O 
	path_group -from $inputs -to $outputs -group I2O  -name I2O
}

##  Slow
set all_regs [all des seqs -clock clk_slow]
define_cost_group -name C2C_slow 
path_group -from $all_regs -to $all_regs -group C2C_slow -name C2C_slow 

set inputs [all des inps -clock clk_slow]
if {[llength $inputs]>0} {
	define_cost_group -name I2C_slow  
	path_group -from $inputs -to $all_regs -group I2C_slow  -name I2C_slow 
}


set outputs [all des outs -clock clk_slow]
if {[llength $outputs]>0} {
	define_cost_group -name C2O_slow  
	path_group -from $all_regs -to $outputs -group C2O_slow  -name C2O_slow 
}

if {[llength $inputs]>0 && [llength $outputs]>0} {
	define_cost_group -name I2O_slow 
	path_group -from $inputs -to $outputs -group I2O_slow  -name I2O_slow 
}



## Map to generic
#######################
syn_gen
syn_map
syn_opt -incremental
syn_opt -incremental
#synthesize -to_generic -effort medium

#synthesize -to_mapped -effort medium

##  Save output
###############
report qor > qor.txt
exec mkdir -p netlist
write_hdl > netlist/minisystem_top.gtl.v
