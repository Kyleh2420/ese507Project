# Makefile for SystemVerilog Compilation and Simulation

#Set default value for MODULE if not specified
MODULE ?= tbench

# Default target when running 'make'
.PHONY: all
all: compile simulate

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
	dc_shell -f runsynth.tcl | tee synth_fifo_out.txt
#Terminal target - runs vsim with an input variable passed as an argument
.PHONY: simulate
simulate:
	@if [ -z "$(MODULE)" ]; then \
		echo "Please specify the testbench: make gui MODULE=<tbench>"; \
	else \
		vsim -64 $(MODULE) -c -do "run -all"; \
	fi

# Help target - shows possible make commands
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make compile         - Compile all .sv files with vlog"
	@echo "  make gui MODULE=<tbench> - Run vsim with the specified testbench in GUI mode (Requires X11)
	@echo "  make simulate MODULE=<tbench> - Run vsim with the specified testbench in command-line mode
