onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /input_mems_tb/dut/INW
add wave -noupdate /input_mems_tb/dut/MAXK
add wave -noupdate /input_mems_tb/dut/K_BITS
add wave -noupdate /input_mems_tb/dut/A_ADDR_BITS
add wave -noupdate /input_mems_tb/dut/B_ADDR_BITS
add wave -noupdate /input_mems_tb/dut/clk
add wave -noupdate /input_mems_tb/dut/reset
add wave -noupdate /input_mems_tb/dut/aDataOut
add wave -noupdate /input_mems_tb/dut/bDataOut
add wave -noupdate /input_mems_tb/dut/aWriteEnable
add wave -noupdate /input_mems_tb/dut/bWriteEnable
add wave -noupdate -divider {Input Data}
add wave -noupdate /input_mems_tb/dut/AXIS_TDATA
add wave -noupdate /input_mems_tb/dut/AXIS_TVALID
add wave -noupdate /input_mems_tb/dut/AXIS_TREADY
add wave -noupdate /input_mems_tb/dut/new_A
add wave -noupdate /input_mems_tb/dut/TUSER_K
add wave -noupdate -divider {Variables Used}
add wave -noupdate /input_mems_tb/errors
add wave -noupdate /input_mems_tb/dut/localA
add wave -noupdate /input_mems_tb/dut/localK
add wave -noupdate /input_mems_tb/dut/M
add wave -noupdate /input_mems_tb/dut/N
add wave -noupdate -divider {State Machine}
add wave -noupdate /input_mems_tb/dut/currentState
add wave -noupdate /input_mems_tb/dut/nextState
add wave -noupdate -divider {Reading I/O}
add wave -noupdate /input_mems_tb/dut/A_read_addr
add wave -noupdate /input_mems_tb/dut/A_data
add wave -noupdate /input_mems_tb/dut/B_read_addr
add wave -noupdate /input_mems_tb/dut/B_data
add wave -noupdate /input_mems_tb/dut/K
add wave -noupdate /input_mems_tb/dut/matrices_loaded
add wave -noupdate /input_mems_tb/dut/aAddress
add wave -noupdate /input_mems_tb/dut/bAddress
add wave -noupdate /input_mems_tb/dut/compute_finished
add wave -noupdate -divider {Indexing Functions}
add wave -noupdate -radix unsigned /input_mems_tb/dut/aCurrentAddress
add wave -noupdate -radix unsigned /input_mems_tb/dut/bCurrentAddress
add wave -noupdate -divider {A Memory}
add wave -noupdate /input_mems_tb/dut/matrixA/data_in
add wave -noupdate /input_mems_tb/dut/matrixA/data_out
add wave -noupdate /input_mems_tb/dut/matrixA/wr_en
add wave -noupdate /input_mems_tb/dut/matrixA/mem
add wave -noupdate -radix unsigned /input_mems_tb/dut/matrixA/addr
add wave -noupdate -divider {B Memory}
add wave -noupdate /input_mems_tb/dut/matrixB/data_in
add wave -noupdate /input_mems_tb/dut/matrixB/data_out
add wave -noupdate -radix unsigned /input_mems_tb/dut/matrixB/addr
add wave -noupdate /input_mems_tb/dut/matrixB/wr_en
add wave -noupdate /input_mems_tb/dut/matrixB/mem
add wave -noupdate -divider {Data In}
add wave -noupdate /input_mems_tb/dut/bDataIn
add wave -noupdate /input_mems_tb/dut/aDataIn
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 3} {13 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 306
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
WaveRestoreZoom {0 ns} {292 ns}
