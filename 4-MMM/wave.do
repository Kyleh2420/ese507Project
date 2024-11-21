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
add wave -noupdate -radix decimal /MMM_tb/dut/OUTPUT_TDATA
add wave -noupdate /MMM_tb/dut/OUTPUT_TVALID
add wave -noupdate /MMM_tb/dut/OUTPUT_TREADY
add wave -noupdate -divider INPUT_MEMS
add wave -noupdate /MMM_tb/dut/inputMem/aWriteEnable
add wave -noupdate /MMM_tb/dut/inputMem/bWriteEnable
add wave -noupdate -radix decimal -childformat {{{/MMM_tb/dut/inputMem/matrixA/mem[15]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[14]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[13]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[12]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[11]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[10]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[9]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[8]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[7]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[6]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[5]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[4]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[3]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[2]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[1]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixA/mem[0]} -radix decimal}} -subitemconfig {{/MMM_tb/dut/inputMem/matrixA/mem[15]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[14]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[13]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[12]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[11]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[10]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[9]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[8]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[7]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[6]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[5]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[4]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[3]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[2]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[1]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixA/mem[0]} {-height 16 -radix decimal}} /MMM_tb/dut/inputMem/matrixA/mem
add wave -noupdate -radix decimal -childformat {{{/MMM_tb/dut/inputMem/matrixB/mem[15]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[14]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[13]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[12]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[11]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[10]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[9]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[8]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[7]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[6]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[5]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[4]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[3]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[2]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[1]} -radix decimal} {{/MMM_tb/dut/inputMem/matrixB/mem[0]} -radix decimal}} -subitemconfig {{/MMM_tb/dut/inputMem/matrixB/mem[15]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[14]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[13]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[12]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[11]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[10]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[9]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[8]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[7]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[6]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[5]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[4]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[3]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[2]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[1]} {-height 16 -radix decimal} {/MMM_tb/dut/inputMem/matrixB/mem[0]} {-height 16 -radix decimal}} /MMM_tb/dut/inputMem/matrixB/mem
add wave -noupdate /MMM_tb/dut/inputMem/newA
add wave -noupdate -divider {FIFO Stuff}
add wave -noupdate -radix decimal /MMM_tb/dut/fifoCapacity
add wave -noupdate -radix decimal /MMM_tb/dut/fifoWriteEnable
add wave -noupdate /MMM_tb/dut/fifoWriteEnableDelay1
add wave -noupdate /MMM_tb/dut/fifoWriteEnableDelay2
add wave -noupdate -radix decimal /MMM_tb/dut/fifo/myMemInst/mem
add wave -noupdate -divider {ADDRESSING & DATA}
add wave -noupdate /MMM_tb/dut/aAddress
add wave -noupdate /MMM_tb/dut/bAddress
add wave -noupdate -radix decimal /MMM_tb/dut/aData
add wave -noupdate -radix decimal /MMM_tb/dut/bData
add wave -noupdate -divider WATCH
add wave -noupdate -radix decimal /MMM_tb/dut/mac/product
add wave -noupdate -radix decimal /MMM_tb/dut/mac/add1
add wave -noupdate -radix decimal /MMM_tb/dut/mac/sum
add wave -noupdate -radix decimal /MMM_tb/dut/macOut
add wave -noupdate -radix decimal /MMM_tb/dut/clearAcc
add wave -noupdate -divider -height 25 {OTHER DATA}
add wave -noupdate /MMM_tb/dut/matricesLoaded
add wave -noupdate /MMM_tb/dut/computeFinished
add wave -noupdate /MMM_tb/dut/validInput
add wave -noupdate /MMM_tb/dut/index
add wave -noupdate /MMM_tb/dut/outputCol
add wave -noupdate /MMM_tb/dut/outputRow
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1605 ns} 0}
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
WaveRestoreZoom {1409 ns} {1803 ns}
