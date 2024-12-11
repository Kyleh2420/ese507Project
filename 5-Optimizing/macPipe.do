onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /MMM_tb/dut/mac/INW
add wave -noupdate /MMM_tb/dut/mac/OUTW
add wave -noupdate /MMM_tb/dut/mac/MINVAL
add wave -noupdate /MMM_tb/dut/mac/MAXVAL
add wave -noupdate /MMM_tb/dut/mac/clk
add wave -noupdate /MMM_tb/dut/mac/reset
add wave -noupdate /MMM_tb/dut/mac/clear_acc
add wave -noupdate /MMM_tb/dut/fifoWriteEnableDelay1
add wave -noupdate /MMM_tb/dut/fifoWriteTrigger
add wave -noupdate /MMM_tb/dut/validInputTrigger
add wave -noupdate /MMM_tb/dut/clearAccDelay1
add wave -noupdate /MMM_tb/dut/clearAccTrigger
add wave -noupdate -divider Math
add wave -noupdate -radix decimal /MMM_tb/dut/mac/in0
add wave -noupdate -radix decimal /MMM_tb/dut/mac/in1
add wave -noupdate -radix decimal /MMM_tb/dut/mac/valid_input
add wave -noupdate -radix decimal /MMM_tb/dut/mac/product
add wave -noupdate -radix decimal /MMM_tb/dut/mac/sum
add wave -noupdate -radix decimal /MMM_tb/dut/mac/add1
add wave -noupdate -radix decimal /MMM_tb/dut/mac/out
add wave -noupdate /MMM_tb/errors
add wave -noupdate -divider Fifo
add wave -noupdate /MMM_tb/dut/fifo/wr_en
add wave -noupdate /MMM_tb/dut/fifo/clk
add wave -noupdate /MMM_tb/dut/fifo/reset
add wave -noupdate -radix decimal /MMM_tb/dut/fifo/data_in
add wave -noupdate /MMM_tb/dut/fifo/wr_en
add wave -noupdate /MMM_tb/dut/fifo/AXIS_TDATA
add wave -noupdate /MMM_tb/dut/fifo/AXIS_TVALID
add wave -noupdate /MMM_tb/dut/fifo/AXIS_TREADY
add wave -noupdate /MMM_tb/dut/fifo/wr_addr
add wave -noupdate /MMM_tb/dut/fifo/rd_addr
add wave -noupdate /MMM_tb/dut/fifo/tail
add wave -noupdate -radix decimal -childformat {{{/MMM_tb/dut/fifo/myMemInst/mem[2]} -radix decimal} {{/MMM_tb/dut/fifo/myMemInst/mem[1]} -radix decimal} {{/MMM_tb/dut/fifo/myMemInst/mem[0]} -radix decimal}} -expand -subitemconfig {{/MMM_tb/dut/fifo/myMemInst/mem[2]} {-height 16 -radix decimal} {/MMM_tb/dut/fifo/myMemInst/mem[1]} {-height 16 -radix decimal} {/MMM_tb/dut/fifo/myMemInst/mem[0]} {-height 16 -radix decimal}} /MMM_tb/dut/fifo/myMemInst/mem
add wave -noupdate /MMM_tb/dut/clearAccDelay
add wave -noupdate /MMM_tb/dut/validDelay
add wave -noupdate /MMM_tb/dut/currentState
add wave -noupdate /MMM_tb/dut/nextState
add wave -noupdate -radix unsigned /MMM_tb/dut/writeCount
add wave -noupdate -expand /MMM_tb/dut/fifoWrEnDelay
add wave -noupdate -radix unsigned /MMM_tb/dut/fifo/capacity
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5470 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 340
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
WaveRestoreZoom {5385 ns} {5715 ns}
