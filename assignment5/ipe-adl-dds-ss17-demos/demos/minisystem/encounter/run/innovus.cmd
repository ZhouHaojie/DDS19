#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Tue Jul  9 14:14:03 2019                
#                                                     
#######################################################

#@(#)CDS: Innovus v16.10-p004_1 (64bit) 05/12/2016 14:48 (Linux 2.6.18-194.el5)
#@(#)CDS: NanoRoute 16.10-p004_1 NR160506-1445/16_10-UB (database version 2.30, 325.6.1) {superthreading v1.28}
#@(#)CDS: AAE 16.10-p003 (64bit) 05/12/2016 (Linux 2.6.18-194.el5)
#@(#)CDS: CTE 16.10-p002_1 () May  3 2016 03:35:25 ( )
#@(#)CDS: SYNTECH 16.10-d040_1 () Apr 22 2016 00:57:16 ( )
#@(#)CDS: CPE v16.10-p007
#@(#)CDS: IQRC/TQRC 15.2.1-s073 (64bit) Tue May  3 11:39:50 PDT 2016 (Linux 2.6.18-194.el5)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getVersion
getDrawView
loadWorkspace -name Physical
win
setDrawView ameba
setDrawView fplan
setDrawView ameba
setDrawView fplan
setDrawView place
setDrawView place
setDrawView place
setDrawView ameba
setDrawView ameba
getCTSMode -engine -quiet
getCTSMode -engine -quiet
getCTSMode -engine -quiet
getCTSMode -engine -quiet
getCTSMode -engine -quiet
getCTSMode -engine -quiet
getCTSMode -engine -quiet
getCTSMode -engine -quiet
getCTSMode -engine -quiet
getCTSMode -engine -quiet
getCTSMode -engine -quiet
setDrawView fplan
freeDesign
setDesignMode -process 65
setDelayCalMode -engine Aae -signoff false -SIAware false
setLimitedAccessFeature ediUsePreRouteGigaOpt 1
setDesignMode -highSpeedCore true
setMultiCpuUsage -localCpu 8 -keepLicense false
setDistributeHost -local
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
create_constraint_mode -name functional -sdc_files $BASE/synthesis/constraints.sdc
create_rc_corner -name rcworstHT   -T 125
create_rc_corner -name rcbestLT   -T 0
create_delay_corner -name worstHTrcw -library_set worstHT -rc_corner rcworstHT
create_delay_corner -name bestLTrcb -library_set bestLT -rc_corner rcbestLT
create_analysis_view -name functional_worstHT -constraint_mode functional -delay_corner worstHTrcw
create_analysis_view -name functional_bestLT -constraint_mode functional -delay_corner bestLTrcb
set init_lef_file {/var/autofs/cadence2/umc-65//65nm-stdcells/lef/tf/uk65lscllmvbbr_9m2t1f.lef /var/autofs/cadence2/umc-65//65nm-stdcells/lef/uk65lscllmvbbr.lef /var/autofs/cadence2/umc-65//65nm-pads/lef/u065gioll18gpir_9m2t2h.lef /var/autofs/cadence2/umc-65//rams/512x32/SJKA65_512X32X1CM4/SJKA65_512X32X1CM4.lef}
set init_verilog /home/ws/ufwhq/dds19/assignment5/ipe-adl-dds-ss17-demos/demos/minisystem/encounter/..//synthesis/run/netlist/minisystem_top.gtl.v
set init_top_cell minisystem_top
suppressMessage ENCLF-122
init_design -setup functional_worstHT -hold functional_bestLT
setOptMode -maxLength 1000
setOptMode -effort low
setOptMode -allEndPoints true
setOptMode -fixFanoutLoad true
set conf_use_io_row_flow 1
setIoFlowFlag 1
floorPlan -b 0 0 1875 1875 88.8 88.8 1786.2 1786.2 108.8 108.8 1766.2 1766.2
uiSetTool move
selectInst fifo_input_async_fifo_I_ram_I_RAM512x32
setObjFPlanBox Instance fifo_input_async_fifo_I_ram_I_RAM512x32 761.5385 1000.9615 1082.8885 1105.3765
deselectAll
selectInst fifo_output_async_fifo_I_ram_I_RAM512x32
setObjFPlanBox Instance fifo_output_async_fifo_I_ram_I_RAM512x32 762.696 761.5385 1084.046 865.9535
fit
cutRow -halo 3
addHaloToBlock 2 2 2 2 -allBlock
addRoutingHalo -allBlocks -space 0.5 -bottom M1 -top M4
addWellTap -cell WT3R -maxGap 118 -checkerBoard -prefix WELLTAP_top
defOut -floorplan floorplan.def
deleteAllSignalPreroutes
clearGlobalNets
addNet -physical VDD_CORE
setNet -net VDD_CORE -type special
addNet -physical GND_CORE
setNet -net GND_CORE -type special
globalNetConnect VDD_CORE -type pgpin -pin VDD -inst * -override -verbose -netlistOverride
globalNetConnect GND_CORE -type pgpin -pin VSS -inst * -override -verbose -netlistOverride
globalNetConnect VDD_CORE -type pgpin -pin VCC -inst * -override -verbose -netlistOverride
globalNetConnect GND_CORE -type pgpin -pin GND -inst * -override -verbose -netlistOverride
globalNetConnect VDD_CORE -type tiehi
globalNetConnect GND_CORE -type tielo
setAddStripeMode -stripe_min_length 10.0
addStripe -direction vertical -layer ME7 -all_blocks 0 -snap_wire_center_to_grid Grid -nets {VDD_CORE GND_CORE} -width 1.4 -spacing 5 -set_to_set_distance 12.8 -xleft_offset 0.0 -ybottom_offset 0.0 -stacked_via_top_layer ME7 -stacked_via_bottom_layer ME6 -block_ring_top_layer_limit ME7 -block_ring_bottom_layer_limit ME6 -padcore_ring_bottom_layer_limit ME6 -padcore_ring_top_layer_limit ME7
addStripe -direction horizontal -layer ME8 -all_blocks 0 -snap_wire_center_to_grid Grid -nets {VDD_CORE GND_CORE} -width 1.4 -spacing 5 -set_to_set_distance 12.8 -xleft_offset 0.0 -ybottom_offset 0.0 -stacked_via_top_layer ME8 -stacked_via_bottom_layer ME7 -block_ring_top_layer_limit ME8 -block_ring_bottom_layer_limit ME7 -padcore_ring_bottom_layer_limit ME7 -padcore_ring_top_layer_limit ME8
sroute -connect { corePin padPin blockPin } -layerChangeRange { 1 6 } -checkAlignedSecondaryPin 1 -allowJogging 0 -crossoverViaBottomLayer 1 -allowLayerChange 1 -targetViaTopLayer 6 -crossoverViaTopLayer 6 -targetViaBottomLayer 1 -nets { GND_CORE  VDD_CORE } -corePinLayer { 1 } -padPinPortConnect allGeom -padPinLayerRange {4 8} -stripeSCpinTarget none
editPowerVia -add_vias 1 -bottom_layer ME1 -top_layer ME8 -skip_via_on_pin {}
createSpareModule -cell {DFQBRM4RA 2 ND2M4R 2 INVM4R 3 INVM12R 1 NR2M2R 2} -moduleName spare_cells_top -tie {TIE1R TIE0R}
placeSpareModule -moduleName spare_cells_top -prefix spare -stepx 200 -stepy 200
placeDesign
checkPlace -noHalo
setTieHiLoMode -cell {TIE1R TIE0R} -maxFanout 1 -maxDistance 20
addTieHiLo -prefix TOP_TIEHILO
extractRC
timeDesign -reportOnly -expandedViews -outDir reports/timing/ -numPaths 100 -prefix placed
timeDesign -reportOnly -expandedViews -outDir reports/timing/ -numPaths 100 -prefix placed_hold -hold
setOptMode -effort low
setCTSMode -reportHTML false
setCTSMode -routeClkNet true
setCTSMode -moveGate true
setCTSMode -moveGateLimit 1000000
setCTSMode -opt true
setCTSMode -optAddBuffer true
setCTSMode -useLibMaxCap true
setCTSMode -useLibMaxFanout false
setAttribute -net CLK -reset
setAttribute -net CLK -preferred_extra_space 1
setAttribute -net CLK -weight 10
setAttribute -net CLK -avoid_detour true
getPlaceMode -doneQuickCTS -quiet
all_hold_analysis_views
all_setup_analysis_views
getPlaceMode -doneQuickCTS -quiet
getDesignMode -process -quiet
getenv CK_SDCDRIVEN_SPEC_DEBUG
all_setup_analysis_views
all_hold_analysis_views
::redirect -quiet { eval $cmd } > /dev/null
check_timing -check_only clock_crossing -verbose -tcl_list
getenv CK_SDCDRIVEN_SPEC_DEBUG
set_analysis_view -setup {functional_worstHT} -hold {functional_bestLT}
all_hold_analysis_views
all_setup_analysis_views
getPlaceMode -doneQuickCTS -quiet
all_hold_analysis_views
all_setup_analysis_views
getPlaceMode -doneQuickCTS -quiet
all_hold_analysis_views
all_setup_analysis_views
getPlaceMode -doneQuickCTS -quiet
all_hold_analysis_views
all_setup_analysis_views
getPlaceMode -doneQuickCTS -quiet
clockDesign
extractRC
timeDesign -reportOnly -expandedViews -outDir reports/timing/ -numPaths 100 -prefix cts
timeDesign -reportOnly -expandedViews -outDir reports/timing/ -numPaths 100 -prefix cts_hold -hold
optDesign -hold -postCTS
timeDesign -reportOnly -expandedViews -outDir reports/timing/ -numPaths 100 -prefix postcts
timeDesign -reportOnly -expandedViews -outDir reports/timing/ -numPaths 100 -prefix postcts_hold -hold
setNanoRouteMode -reset
setMaxRouteLayer 6
setNanoRouteMode -routeTopRoutingLayer 6
setNanoRouteMode -routeWithTimingDriven true
setNanoRouteMode -routeWithSiDriven true
setNanoRouteMode -routeWithViaInPin 1:1
setNanoRouteMode -drouteOnGridOnly true
setNanoRouteMode -routeAntennaCellName ANTR
setNanoRouteMode -routeStrictlyHonorNonDefaultRule true
setNanoRouteMode -drouteUseMultiCutViaEffort low
setNanoRouteMode -routeConcurrentMinimizeViaCountEffort low
setNanoRouteMode -routeReserveSpaceForMultiCut false
setNanoRouteMode -droutePostRouteSwapVia none
getPlaceMode -doneQuickCTS -quiet
setNanoRouteMode -routeWithTimingDriven true
setNanoRouteMode -routeWithSiDriven true
routeDesign
setNanoRouteMode -routeReserveSpaceForMultiCut false
dbGet top.statusRouted
dbGet top.statusRCExtracted
extractRC
timeDesign -reportOnly -expandedViews -outDir reports/timing/ -numPaths 100 -prefix route
setFillerMode -core {FIL64R FIL32R FIL16R FIL8R FIL4R FIL2R FIL1R}
addFiller
ecoRoute
verifyGeometry
selectWire 1350.4000 108.8000 1351.8000 1766.2000 7 VDD_CORE
editMove 556.731 -28.8465
editMove 49.0385 -167.3075
deselectAll
selectObject StdRow (3572400,177600,3750000,3572400)
setObjFPlanBox StdRow (3572400,177600,3750000,3572400) 1652.4175 497.3 1741.2175 2194.7
setObjFPlanBox StdRow (3304830,355200,3482430,3750000) 1536.0825 379.6095 1624.8825 2077.0095
zoomIn
zoomIn
zoomIn
zoomIn
setDrawView ameba
setDrawView ameba
setDrawView place
setDrawView place
setDrawView place
zoomBox 2630.930 719.503 2630.881 719.503
setDrawView ameba
setDrawView fplan
freeDesign
setDesignMode -process 65
setDelayCalMode -engine Aae -signoff false -SIAware false
setLimitedAccessFeature ediUsePreRouteGigaOpt 1
setDesignMode -highSpeedCore true
setMultiCpuUsage -localCpu 8 -keepLicense false
setDistributeHost -local
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
create_constraint_mode -name functional -sdc_files $BASE/synthesis/constraints.sdc
create_rc_corner -name rcworstHT   -T 125
create_rc_corner -name rcbestLT   -T 0
create_delay_corner -name worstHTrcw -library_set worstHT -rc_corner rcworstHT
create_delay_corner -name bestLTrcb -library_set bestLT -rc_corner rcbestLT
create_analysis_view -name functional_worstHT -constraint_mode functional -delay_corner worstHTrcw
create_analysis_view -name functional_bestLT -constraint_mode functional -delay_corner bestLTrcb
set init_lef_file {/var/autofs/cadence2/umc-65//65nm-stdcells/lef/tf/uk65lscllmvbbr_9m2t1f.lef /var/autofs/cadence2/umc-65//65nm-stdcells/lef/uk65lscllmvbbr.lef /var/autofs/cadence2/umc-65//65nm-pads/lef/u065gioll18gpir_9m2t2h.lef /var/autofs/cadence2/umc-65//rams/512x32/SJKA65_512X32X1CM4/SJKA65_512X32X1CM4.lef}
set init_verilog /home/ws/ufwhq/dds19/assignment5/ipe-adl-dds-ss17-demos/demos/minisystem/encounter/..//synthesis/run/netlist/minisystem_top.gtl.v
set init_top_cell minisystem_top
suppressMessage ENCLF-122
init_design -setup functional_worstHT -hold functional_bestLT
setOptMode -maxLength 1000
setOptMode -effort low
setOptMode -allEndPoints true
setOptMode -fixFanoutLoad true
selectInst datain_io
setObjFPlanBox Instance datain_io 418.9215 91.6075 507.7215 151.6075
redraw
redraw
redraw
setObjFPlanBox Instance datain_io 416.675 90.477 505.475 150.477
redraw
redraw
redraw
redraw
redraw
redraw
redraw
redraw
redraw
