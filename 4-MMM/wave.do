onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /MMM_tb/dut/clk
add wave -noupdate /MMM_tb/errors
add wave -noupdate /MMM_tb/dut/reset
add wave -noupdate /MMM_tb/dut/currentState
add wave -noupdate -divider -height 25 PARAMETERS
add wave -noupdate /MMM_tb/dut/INW
add wave -noupdate /MMM_tb/dut/OUTW
add wave -noupdate /MMM_tb/dut/M
add wave -noupdate /MMM_tb/dut/N
add wave -noupdate /MMM_tb/dut/MAXK
add wave -noupdate /MMM_tb/dut/K_BITS
add wave -noupdate /MMM_tb/dut/K
add wave -noupdate -divider -height 25 {DATA IN}
add wave -noupdate -radix decimal /MMM_tb/dut/INPUT_TDATA
add wave -noupdate /MMM_tb/dut/INPUT_TVALID
add wave -noupdate /MMM_tb/dut/INPUT_TUSER
add wave -noupdate /MMM_tb/dut/INPUT_TREADY
add wave -noupdate -divider -height 25 {DATA OUT}
add wave -noupdate /MMM_tb/dut/OUTPUT_TDATA
add wave -noupdate /MMM_tb/dut/OUTPUT_TVALID
add wave -noupdate /MMM_tb/dut/OUTPUT_TREADY
add wave -noupdate -divider {ADDRESSING & DATA}
add wave -noupdate /MMM_tb/dut/aAddress
add wave -noupdate /MMM_tb/dut/bAddress
add wave -noupdate -radix decimal /MMM_tb/dut/aData
add wave -noupdate -radix decimal /MMM_tb/dut/bData
add wave -noupdate -radix decimal /MMM_tb/dut/macOut
add wave -noupdate -divider WATCH
add wave -noupdate -radix decimal /MMM_tb/dut/mac/product
add wave -noupdate -radix decimal /MMM_tb/dut/mac/sum
add wave -noupdate -divider -height 25 {OTHER DATA}
add wave -noupdate /MMM_tb/dut/matricesLoaded
add wave -noupdate /MMM_tb/dut/computeFinished
add wave -noupdate /MMM_tb/dut/clearAcc
add wave -noupdate /MMM_tb/dut/validInput
add wave -noupdate /MMM_tb/dut/fifoWriteEnable
add wave -noupdate /MMM_tb/dut/fifoCapacity
add wave -noupdate /MMM_tb/dut/index
add wave -noupdate /MMM_tb/dut/outputRow
add wave -noupdate /MMM_tb/dut/outputCol
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {115 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 335
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
WaveRestoreZoom {0 ns} {264 ns}
