// ESE 507 Stony Brook University
// Peter Milder
// You may not redistribute this code.
// Testbench for mac_pipe and mac_unpipe modules

// To use this testbench:
// Compile it and your accompanying design with:
//   vlog -64 +acc mac_tb.sv [add your other .sv files to simulate here]
//   vsim -64 -c mac_tb -sv_seed random 
//      [options]:
//       - If you want to run in GUI mode, remove -c

// Note that this testbench relies on params.sv, which can be generated 
// using the ./genParams1 script. See instructions in the project description.

// Please see the project description for a high-level description of this testbench and how to run it. Comments are also included throughout to help understand how the testbench works.

// Import the C functions (from mac_tb.c) that will calculate the expected outputs of the MAC unit, for pipelined and unpipelined MACs.
import "DPI-C" function void sim_cycle_pipelined(input int in0, input int in1, input bit valid_input, input bit clear_acc, output longint res, input int OUTW);
import "DPI-C" function void sim_cycle_unpipelined(input int in0, input int in1, input bit valid_input, input bit clear_acc, output longint res, input int OUTW);

// Include the params.sv file, which holds the parameter values
`include "params.sv"

// A class to hold one instance of test data and associated control logic.
// When we call  .randomize() on an object of this class, it will randomly 
// generate values for the inputs in0, in1, and control signals valid_input and 
// clear_acc. The clear_acc signal will be constrained such that it is usually 
// (99%) of the time 0.
class testdata #(parameter INW=8);
    rand logic signed [INW-1:0] in0, in1;
    rand bit valid_input;
    rand bit clear_acc;
    constraint c {clear_acc dist {0:=99, 1:=1};}
endclass

    

module mac_tb();
    
    parameter TESTS = 10000;             // the number of cycles of input to simulate
    parameter INW   = `INWVAL;           // the number of bits in the inputs
    parameter OUTW  = `OUTWVAL;          // the number of bits in the output
    parameter PIPELINED = `PIPELINEDVAL; // 0 for unpipelined design, 1 for pipelined design

    logic clk, reset;
    initial clk = 0;
    always #5 clk = ~clk;

    logic signed [INW-1:0] in0, in1;
    logic signed [OUTW-1:0] out, out_exp;
    logic valid_input, clear_acc;

    // Instantiate the DUT based on PIPELINED parameter
    generate 
        if (PIPELINED == 1)
            mac_pipe #(INW, OUTW) dut(in0, in1, out, clk, reset, clear_acc, valid_input);
        else
            mac #(INW, OUTW) dut(in0, in1, out, clk, reset, clear_acc, valid_input);
    endgenerate

    // An object of class "testdata" (See class definition above)
    testdata #(INW) td;

    // Count how many times the testbench identifies errors in the design.
    logic [31:0] errors;

    // Check and display simulation parameters
    initial begin
        if ((INW < 2) || (INW > 32)) begin
            $error("PARAMETER ERROR: INW must be >= 2 and <= 32");
            $stop;
        end
        
        if ((OUTW < 2) || (OUTW > 64)) begin
            $error("PARAMETER ERROR: OUTW must be >= 2 and <= 64");
            $stop;
        end

        $display("--------------------------------------------------------");
        $display("Starting MAC unit simulation: %d tests", TESTS);
        $display("Pipelining: %d", PIPELINED);            
        $display("Input %d bits\nOutput: %d bits", INW, OUTW);
        $display("--------------------------------------------------------");
    end


    initial begin
        errors = 0;
        reset = 1;
        valid_input = 0;
        clear_acc = 0;
        @(posedge clk);
        #1;

        td = new();

        // For each test, randomize the td object. Then set the DUT inputs
        // to match. Lastly, call the appropriate C function using the DPI
        // interface, which will compute the expected output for this
        // cycle, and check that the result matches.
        repeat(TESTS) begin
            reset = 0;
            assert(td.randomize());
            in0 = td.in0;
            in1 = td.in1;
            valid_input = td.valid_input;
            clear_acc = td.clear_acc;            

            if (PIPELINED == 1)
                sim_cycle_pipelined(td.in0, td.in1, td.valid_input, td.clear_acc, out_exp, OUTW);
            else 
                sim_cycle_unpipelined(td.in0, td.in1, td.valid_input, td.clear_acc, out_exp, OUTW);

            @(posedge clk);
            #1;

            if (out !== out_exp) begin
                $display($time,, "ERROR: MAC output: %d. Expected output: %d", out, out_exp);
                errors = errors+1;
            end

        end

        $display("Simulation finished with %d errors", errors);

        #10;
        $finish;
    end

endmodule

