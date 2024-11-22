# Makefile for SystemVerilog Compilation and Simulation

#Set default value for MODULE if not specified
MODULE ?= tbench

#Defaults for simParams and genParams
INW ?= 3
OUTW ?= 8
M ?= 3
N ?= 3
MAXK ?= 3
TVALID_PROB ?= .5
TREADY_PROB ?= .5
GUI ?= 0

# Default target when running 'make'
.PHONY: all
all: genParams compile simParams

# Compile target - compiles all .sv files using vlog
.PHONY: compile
compile:
	vlog -64 +acc *.sv

# GUI target - runs vsim with an input variable passed as an argument
.PHONY: gui
gui:
	@if [ -z "$(MODULE)" ]; then \
		echo "Please specify the testbench: make gui MODULE=<tbench>"; \
	else \
		vsim -64 $(MODULE) & \
	fi

#Sets up the folder for synthesis. Requires the default files to be edited
.PHONY: synthSetup
synthSetup:
	cp /home/home4/pmilder/ese507/synthesis/scripts/setupdc.tcl .
	cp /home/home4/pmilder/ese507/synthesis/scripts/runsynth.tcl .
	
#Runs the synthesis and sends the output to output.txt
.PHONY: synth
synth:
	dc_shell -f runsynth.tcl | tee synth_input_mems.txt

#Terminal target - runs vsim with an input variable passed as an argument
.PHONY: simulate
simulate:
	@if [ -z "$(MODULE)" ]; then \
		echo "Please specify the testbench: make gui MODULE=<tbench>"; \
	else \
		vsim -64 $(MODULE) -c -do "run -all"; \
	fi

.PHONY: genParams
genParams:
	./genParams4 $(INW) $(OUTW) $(M) $(N) $(MAXK) $(TVALID_PROB) $(TREADY_PROB)

.PHONY: simParams
	./simParams4 $(INW) $(OUTW) $(M) $(N) $(MAXK) $(TVALID_PROB) $(TREADY_PROB) $(GUI) 

# Help target - shows possible make commands
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make compile         - Compile all .sv files with vlog"
	@echo "  make gui MODULE=<tbench> - Run vsim with the specified testbench in GUI mode (Requires X11)
	@echo "  make simulate MODULE=<tbench> - Run vsim with the specified testbench in command-line mode
