##############################################
# Setup: fill out the following parameters: name of clock signal, clock period (ns),
# reset signal name (if used), name of top-level module, name of source file
set CLK_NAME "clk";
set CLK_PERIOD 1;
set RST_NAME "reset";
set TOP_MOD_NAME "MMM";
set SRC_FILE [list "MMM.sv" "input_mems.sv" "mac_pipe.sv" "fifo_out.sv"];

# set CLK_NAME "clk";
# set CLK_PERIOD 2;
# set RST_NAME "reset";
# set TOP_MOD_NAME "mac_pipe";
# set SRC_FILE "mac_pipe.sv";

# set CLK_NAME "clk";
# set CLK_PERIOD 1;
# set RST_NAME "reset";
# set TOP_MOD_NAME "input_mems";
# set SRC_FILE "input_mems.sv";
# If you have multiple source files, change the line above to list them all like this:
# set SRC_FILE [list "file1.sv" "file2.sv"];
###############################################

# setup
source setupdc.tcl
file mkdir work_synth
date
pid
pwd
getenv USER
getenv HOSTNAME


# optimize FSMs
set fsm_auto_inferring "true"; 
set fsm_enable_state_minimization "true";

define_design_lib WORK -path work_synth
analyze $SRC_FILE -format sverilog
elaborate -work WORK $TOP_MOD_NAME

###### CLOCKS AND PORTS #######
set CLK_PORT [get_ports $CLK_NAME]
set TMP1 [remove_from_collection [all_inputs] $CLK_PORT]
set INPUTS [remove_from_collection $TMP1 $RST_NAME]
create_clock -period $CLK_PERIOD $CLK_PORT
set_input_delay 0.08 -max -clock $CLK_NAME $INPUTS
set_output_delay 0.08 -max -clock $CLK_NAME [all_outputs]


###### OPTIMIZATION #######
set_max_area 0 

###### RUN #####
compile_ultra
report_area
report_power
report_timing
report_timing -loops
date
# write -f verilog $TOP_MOD_NAME -output gates.v -hierarchy

quit

