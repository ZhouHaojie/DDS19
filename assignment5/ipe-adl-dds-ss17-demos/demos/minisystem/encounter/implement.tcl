
## Floorplan
#######################

## IO 
setUserDataValue conf_use_io_row_flow 1
setIoFlowFlag 1

## Resize Floorplan


## Min Size of mini asic run: 1875x1875
floorPlan -b 0 0 1875 1875 88.8 88.8 [expr 1875-88.8]  [expr 1875-88.8] 108.8 108.8 [expr 1875-108.8]  [expr 1875-108.8]

## Place rams
uiSetTool move
selectInst fifo_input_async_fifo_I_ram_I_RAM512x32
setObjFPlanBox Instance fifo_input_async_fifo_I_ram_I_RAM512x32 761.5385 1000.9615 1082.8885 1105.3765
deselectAll
selectInst fifo_output_async_fifo_I_ram_I_RAM512x32
setObjFPlanBox Instance fifo_output_async_fifo_I_ram_I_RAM512x32 762.696 761.5385 1084.046 865.9535
fit

## Cut Rows, Set Halos around blocks and add Well Taps

## cut Rows around ram
cutRow -halo 3
addHaloToBlock 2 2 2 2 -allBlock
addRoutingHalo -allBlocks -space 0.5 -bottom M1 -top M4


## Add Welltaps

# LUP.6 states the maximus radius R for a well-tap as 30um
# spacing between well-tap cells must be less than 2*sqrt (R^2 - H^2) with H being the std. cell height
# --> S = 2*sqrt (30^2 - 2.4^2) = 59.80 which aligns to the M2 routing pitch of 0.2um
addWellTap -cell WT3R -maxGap 118 -checkerBoard -prefix WELLTAP_top

## Save DEF

defOut -floorplan floorplan.def





## Power
########################

#### Create Global nets  for VDD/VSS in core Area

## clean a bit first
deleteAllSignalPreroutes
clearGlobalNets

#try to create power nets
catch {  
  addNet -physical VDD_CORE
  setNet -net VDD_CORE -type special
  dbSetIsNetPwr VDD_CORE
 
  addNet -physical GND_CORE
  setNet -net GND_CORE -type special
  dbSetIsNetGnd GND_CORE
}

#### Make Global net connections for Standard Cells and RAM


## Stdcell
globalNetConnect VDD_CORE    -type pgpin -pin {VDD}    -inst * -override -verbose -netlistOverride
globalNetConnect GND_CORE    -type pgpin -pin {VSS}    -inst * -override -verbose -netlistOverride

## RAMS 
globalNetConnect VDD_CORE    -type pgpin -pin {VCC}    -inst * -override -verbose -netlistOverride
globalNetConnect GND_CORE    -type pgpin -pin {GND}    -inst * -override -verbose -netlistOverride

## 0/1 constants in design are tiehi/low
globalNetConnect VDD_CORE    -type tiehi
globalNetConnect GND_CORE    -type tielo

## Cover Core area with Power Stripes.
## Put stripes on layers 7/8 is ok, 9 and Redistribution remain then free for IO routing
setAddStripeMode -stripe_min_length 10.0

addStripe -direction vertical -layer ME7 -all_blocks 0 \
-snap_wire_center_to_grid Grid -nets {VDD_CORE GND_CORE} -width 1.4 -spacing 5 \
-set_to_set_distance 12.8 -xleft_offset 0.0 -ybottom_offset 0.0 \
-stacked_via_top_layer ME7 -stacked_via_bottom_layer ME6 \
-block_ring_top_layer_limit ME7 -block_ring_bottom_layer_limit ME6 \
-padcore_ring_bottom_layer_limit ME6 -padcore_ring_top_layer_limit ME7 

addStripe -direction horizontal -layer ME8 -all_blocks 0 \
-snap_wire_center_to_grid Grid -nets {VDD_CORE GND_CORE} -width 1.4 -spacing 5 \
-set_to_set_distance 12.8 -xleft_offset 0.0 -ybottom_offset 0.0 \
-stacked_via_top_layer ME8 -stacked_via_bottom_layer ME7 \
-block_ring_top_layer_limit ME8 -block_ring_bottom_layer_limit ME7 \
-padcore_ring_bottom_layer_limit ME7 -padcore_ring_top_layer_limit ME8



# Now We can finish power connections by calling sroute, and adding power vias from power stripes down to power structures for RAM and standard cells
sroute -connect { corePin padPin blockPin } -layerChangeRange { 1 6 } \
-checkAlignedSecondaryPin 1 -allowJogging 0 -crossoverViaBottomLayer 1 \
-allowLayerChange 1 -targetViaTopLayer 6 -crossoverViaTopLayer 6 \
-targetViaBottomLayer 1 -nets { GND_CORE  VDD_CORE } -corePinLayer { 1 } \
-padPinPortConnect allGeom -padPinLayerRange {4 8} \
-stripeSCpinTarget none


editPowerVia -add_vias 1 -bottom_layer ME1 -top_layer ME8 -skip_via_on_pin {}

## EOF Power ##

## Place 
#######################

## Place spares
createSpareModule -cell {DFQBRM4RA 2 ND2M4R 2 INVM4R 3 INVM12R 1 NR2M2R 2} \
        -moduleName spare_cells_top -tie {TIE1R TIE0R}

placeSpareModule -moduleName spare_cells_top -prefix spare -stepx 200 -stepy 200

## Place 
placeDesign

##  CHECK PLACEMENT!!
checkPlace -noHalo




## Add Tie Hi/Low
setTieHiLoMode -cell {TIE1R TIE0R} -maxFanout 1 -maxDistance 20
addTieHiLo -prefix TOP_TIEHILO


## Time Design
if {[dbGet top.statusRouted]      == 0} {trialRoute}
if {[dbGet top.statusRCExtracted] == 0} {extractRC}
exec mkdir -p reports/timing/
timeDesign -reportOnly -expandedViews -outDir reports/timing/  -numPaths 100 -prefix placed
timeDesign -reportOnly -expandedViews -outDir reports/timing/  -numPaths 100 -prefix placed_hold -hold

##  EOF PLACE ##

## Clock Synthesis
########################


## Opt Design  (ignore here to avoid long runtimes)
setOptMode -effort low
#optDesign -preCTS



## List allowed buffers 
set clockBuffersList {}
lappend clockBuffersList CKBUFM4R CKBUFM8R CKBUFM12R
lappend clockBuffersList CKINVM4R CKINVM8R CKINVM12R

## Set Mode
setCTSMode -reportHTML             false
setCTSMode -routeClkNet            true
setCTSMode -moveGate               true
setCTSMode -moveGateLimit          1000000
setCTSMode -opt                    true
setCTSMode -optAddBuffer           true
setCTSMode -useLibMaxCap           true
setCTSMode -useLibMaxFanout        false


set clkNet CLK

setAttribute -net $clkNet -reset

## Double Spacing
setAttribute -net $clkNet -preferred_extra_space 1

## Higher priority
setAttribute -net $clkNet -weight 10

## Avoid detour
setAttribute -net $clkNet -avoid_detour true



## Generate Spec
# -bufferList $clockBuffersList
cleanupSpecifyClockTree
createClockTreeSpec -clkGroup -bufferList $clockBuffersList -file encrypter.ctstch

## Do
exec mkdir -p reports/cts/
specifyClockTree -clkfile encrypter.ctstch
changeClockStatus -noFixedBuffers -noFixedLeafInst -noFixedNetWires -all

catch {deleteClockTree -all}
clockDesign

# Time design and save it
exec mkdir -p reports/timing/
if {[dbGet top.statusRouted]      == 0} {trialRoute}
if {[dbGet top.statusRCExtracted] == 0} {extractRC}
timeDesign -reportOnly -expandedViews -outDir reports/timing/  -numPaths 100 -prefix cts
timeDesign -reportOnly -expandedViews -outDir reports/timing/  -numPaths 100 -prefix cts_hold -hold


## Hold fix 
optDesign -hold -postCTS

## Reporting
timeDesign -reportOnly -expandedViews -outDir reports/timing/  -numPaths 100 -prefix postcts
timeDesign -reportOnly -expandedViews -outDir reports/timing/  -numPaths 100 -prefix postcts_hold -hold


#### EOF CTS ####################""


## Route
#########################


## Set Mode
setNanoRouteMode -reset

## Low effort to avoid long runtimes

setMaxRouteLayer 6
#setNanoRouteMode -routeBottomRoutingLayer 2
setNanoRouteMode -routeTopRoutingLayer    6

setNanoRouteMode -routeWithTimingDriven                 true
setNanoRouteMode -routeWithSiDriven                     true

# virage std cells
setNanoRouteMode -routeWithViaInPin                     1:1  ; # true
#setNanoRouteMode -routeWithViaOnlyForStandardCellPin    1:1  ; # true
#setNanoRouteMode -drouteOnGridOnly                      via  ; # default: none (none | via | all), VL recommend!?!
#setNanoRouteMode -drouteOnGridOnly                      true ;
#setNanoRouteMode -drouteViaOnGridOnly                   true ;
#setNanoRouteMode -envAlignNonPreferredTrack             true ; # is obsolete and will be removed in future release, VL recommend!?!
#set nanoroute mode to prevent DRCs (rever to std lib docu)
setNanoRouteMode -drouteOnGridOnly true


### set antenna diode cell
setNanoRouteMode -routeAntennaCellName ANTR       

# SI
setNanoRouteMode -routeStrictlyHonorNonDefaultRule      true

# DFM
#setNanoRouteMode -routeWithLithoDriven                  true
setNanoRouteMode -drouteUseMultiCutViaEffort            low
setNanoRouteMode -routeConcurrentMinimizeViaCountEffort low
setNanoRouteMode -routeReserveSpaceForMultiCut          false
setNanoRouteMode -droutePostRouteSwapVia                none






##### standard hsNanoRoute
changeUseClockNetStatus -noFixedNetWires
setNanoRouteMode -routeWithTimingDriven                  true
setNanoRouteMode -routeWithSiDriven                      true

## Run Route
routeDesign


##### custom command
setNanoRouteMode -routeReserveSpaceForMultiCut            false

# Time design and save it
if {[dbGet top.statusRouted]      == 0} {trialRoute}
if {[dbGet top.statusRCExtracted] == 0} {extractRC}
timeDesign -reportOnly -expandedViews -outDir reports/timing/  -numPaths 100 -prefix route

## Add Fillers
#####################
set _fillers {}

lappend _fillers FIL64R
lappend _fillers FIL32R
lappend _fillers FIL16R
lappend _fillers FIL8R
lappend _fillers FIL4R
lappend _fillers FIL2R
lappend _fillers FIL1R

setFillerMode -core $_fillers

addFiller

## run a route comand to clean DRC errors
ecoRoute

## verify geometry
verifyGeometry
