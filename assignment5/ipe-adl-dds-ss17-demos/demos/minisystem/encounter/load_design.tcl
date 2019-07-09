

## Location of the current script
set BASE [file dirname [file normalize [info script]]]/../

## First Free the design 
catch {freeDesign}

## 65nm configuration
setDesignMode -process 65
setDelayCalMode -engine Aae -signoff false -SIAware false


## Tool setup 
setLimitedAccessFeature ediUsePreRouteGigaOpt 1
setDesignMode -highSpeedCore true
setMultiCpuUsage -localCpu 8 -keepLicense false
setDistributeHost -local

#### MMMC Setup
###############################

## Load Library files using Multi Mode Multi Corner
#########################

#### First: Create Library Sets 
create_library_set -name worstHT \
    -timing [list $::env(UMC_HOME)/65nm-stdcells/synopsys/uk65lscllmvbbr_108c125_wc.lib \
     $::env(UMC_HOME)/65nm-pads/synopsys/u065gioll18gpir_wc.lib] \
    -si     [list $::env(UMC_HOME)/65nm-stdcells/synopsys/uk65lscllmvbbr_108c125_wc.db \
     $::env(UMC_HOME)/65nm-pads/synopsys/u065gioll18gpir_wc.db]

create_library_set -name bestLT \
    -timing [list $::env(UMC_HOME)/65nm-stdcells/synopsys/uk65lscllmvbbr_132c0_bc.lib \
      $::env(UMC_HOME)/65nm-pads/synopsys/u065gioll18gpir_bc.lib] \
    -si     [list $::env(UMC_HOME)/65nm-stdcells/synopsys/uk65lscllmvbbr_132c0_bc.db \
      $::env(UMC_HOME)/65nm-pads/synopsys/u065gioll18gpir_bc.db]


#### Second: Constraints, use from synthesis folder
create_constraint_mode -name functional -sdc_files $BASE/synthesis/constraints.sdc


#### Third: Create a delay corner ??
create_rc_corner -name rcworstHT   -T 125
create_rc_corner -name rcbestLT   -T 0

create_delay_corner -name worstHTrcw -library_set worstHT -rc_corner rcworstHT
create_delay_corner -name bestLTrcb -library_set bestLT -rc_corner rcbestLT


#### Final: Create view
create_analysis_view -name functional_worstHT -constraint_mode functional -delay_corner worstHTrcw
create_analysis_view -name functional_bestLT -constraint_mode functional -delay_corner bestLTrcb

## LEF Files 
######################

set init_lef_file [list \
    $::env(UMC_HOME)/65nm-stdcells/lef/tf/uk65lscllmvbbr_9m2t1f.lef \
    $::env(UMC_HOME)/65nm-stdcells/lef/uk65lscllmvbbr.lef \
    $::env(UMC_HOME)/65nm-pads/lef/u065gioll18gpir_9m2t2h.lef \
    $::env(UMC_HOME)/rams/512x32/SJKA65_512X32X1CM4/SJKA65_512X32X1CM4.lef]

#    $::env(UMC_HOME)/65nm-pads/lef/u065gioll18gpir_9m2t2h.lef \
$::env(UMC_HOME)/65nm-pads/lef/tf/u065gioll18gpir_9m2t2h.lef

## Set Design
###############################
set init_verilog "$BASE/synthesis/run/netlist/minisystem_top.gtl.v"
set init_top_cell minisystem_top

## Init
#########################

suppressMessage ENCLF-122

## Init design by giving corner pairs for hold/setup
init_design -setup [list functional_worstHT ] -hold [list functional_bestLT]



#### Opt Mode Setup 
###################
setOptMode -maxLength    1000
setOptMode -effort low          
setOptMode -allEndPoints true
setOptMode -fixFanoutLoad true
