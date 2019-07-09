## Select technology library
<<<<<<< HEAD

set_db library /path
=======
<<<<<<< HEAD

set_db library /path
=======
set_db library /var/autofs/cadence/umc-65/65nm-stdcells/synopsys/uk65lscllmvbbr_090c125_wc.lib

## counter_top is in the current older
## couter is taken from assignment one
## both files passed as a list, hence the {...}syntax
## -v2001 means "verilog 2001" syntax
read_hdl -v2001 {counter_top.v ../assignment1/counter.v}

## run elaboration
elaborate

## load the SDC file
read_sdc contraints.sdc

set all_regs [all des seqs -clock clk]
define_cost_group -name C2C
path_group -from $all_regs -to $all_regs -group C2C -name C2C

set inputs [all des inps -clock clk]
define_cost_group -name I2C
path_group -from $inputs -to $all_regs -group I2C -name I2C

set outputs [all des outs -clock clk]
define_cost_group -name C2O
path_group -from $all_regs -to $outputs -group C2O -name C2O

define_cost_group -name I2O
path_group -from $inputs -to $outputs -group I2O -name I2O 

synthesize -to_mapped -effort medium
synthesize -to_mapped -incr -effort medium
>>>>>>> second
>>>>>>> second
