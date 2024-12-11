onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /MMM_tb/dut/currentState
add wave -noupdate /MMM_tb/dut/nextState
add wave -noupdate /MMM_tb/dut/aAddress
add wave -noupdate /MMM_tb/dut/bAddress
add wave -noupdate -divider -height 25 INTERFACE
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/INW
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/M
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/N
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/MAXK
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/K_BITS
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/A_ADDR_BITS
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/B_ADDR_BITS
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/clk
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/reset
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/AXIS_TDATA
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/AXIS_TVALID
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/AXIS_TUSER
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/AXIS_TREADY
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/matrices_loaded
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/compute_finished
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/K
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/A_read_addr
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/A_data
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/B_read_addr
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/B_data
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/newAOut
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/newA
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/TUSER_K
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/currentState
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/aCurrentAddress
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/bCurrentAddress
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/localK
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/localA
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/aAddress
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/bAddress
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/aWriteEnable
add wave -noupdate /MMM_tb/dut/inputMem/input_interface/bWriteEnable
add wave -noupdate -divider -height 25 COMPUTATION
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/INW
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/M
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/N
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/MAXK
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/K_BITS
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/A_ADDR_BITS
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/B_ADDR_BITS
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/clk
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/reset
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/A_data_in
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/A_addr_in
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/B_data_in
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/B_addr_in
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/finishedLoading
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/getNewData
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/K_in
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/newAIn
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/A_read_addr
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/B_read_addr
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/B_data
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/A_data
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/matrices_loaded
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/compute_finished
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/K
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/currentState
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/nextState
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/aCurrentAddress
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/bCurrentAddress
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/aAddress
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/bAddress
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/aWriteEnable
add wave -noupdate /MMM_tb/dut/inputMem/input_computation/bWriteEnable
add wave -noupdate -divider {input_mem level}
add wave -noupdate /MMM_tb/dut/inputMem/aAddress
add wave -noupdate /MMM_tb/dut/inputMem/bAddress
add wave -noupdate /MMM_tb/dut/inputMem/aData
add wave -noupdate /MMM_tb/dut/inputMem/bData
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {330 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 408
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1050 ns}
