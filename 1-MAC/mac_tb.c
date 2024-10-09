// ESE 507 Stony Brook University
// Peter Milder
// You may not redistribute this code.
// Testbench for mac_pipe and mac modules


// This file contains the DPI functions used in the MAC testbench.
// For each simulation cycle, the testbench will call this
// sim_cycle function, which computes the expected values of the registers
// and output.

#include <svdpi.h>
#include <stdio.h>


// Global variables that will store the simulated state
long int prod_pipe = 0;
int prod_valid = 0;
long int accum = 0;

// Simulate one cycle of the pipelined system. The expected result will be stored in res, where it
// can be read by the testbench.
void sim_cycle_pipelined(svBitVecVal in0, svBitVecVal in1, svBitVecVal valid_data, svBitVecVal clear_acc, svBitVecVal* res, svBitVecVal OUTW) {
    int a = (int)in0;   
    int b = (int)in1;

    // simulate the accumulator register
    if (clear_acc == 1) {
        accum = 0;
        *((long int*)res) = accum;
    }
    else if (prod_valid) {
        long old_accum = accum;
        accum += prod_pipe; 

        long min = -1*(1l<<(OUTW-1));
        long max = (1l<<(OUTW-1))-1;

        // special case if output takes up the full 64 bits available in long 
        if (OUTW == 64) {
            if ((old_accum > 0) && (prod_pipe > 0) && (accum < 0))
                accum = max;
            else if ((old_accum < 0) && (prod_pipe < 0) && (accum > 0))
                accum = min;
        }
        else {
            if (accum < min)
                accum = min;
            else if (accum > max)
                accum = max;
        }


        *((long int*)res) = accum;
    }
    
    prod_pipe = (long)a * (long)b;
    prod_valid = valid_data;
}

// Simulate one cycle. The expected result will be stored in res, where it
// can be read by the testbench.
void sim_cycle_unpipelined(svBitVecVal in0, svBitVecVal in1, svBitVecVal valid_data, svBitVecVal clear_acc, svBitVecVal* res, svBitVecVal OUTW) {
    if (clear_acc == 1) {
        accum = 0;
        *((long int*)res) = accum;
    }
    else if (valid_data) {
        int a = (int)in0;   
        int b = (int)in1;

        long prod = (long)a * (long)b;
        long old_accum = accum;
        accum += prod;

        long min = -1*(1l<<(OUTW-1));
        long max = (1l<<(OUTW-1))-1;

        // special case if output takes up the full 64 bits available in long 
        if (OUTW == 64) {
            if ((old_accum > 0) && (prod > 0) && (accum < 0))
                accum = max;
            else if ((old_accum < 0) && (prod < 0) && (accum > 0))
                accum = min;
        }
        else {
            if (accum < min)
                accum = min;
            else if (accum > max)
                accum = max;
        }

        *((long int*)res) = accum;
    }
}