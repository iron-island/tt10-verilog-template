# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

FILENAME = "./txt/example17.txt"

def parse_input(filename):

    with open(filename) as f:
        input_list = f.read().split("\n")

    reg_A = int(input_list[0].split(": ")[1])
    reg_B = int(input_list[1].split(": ")[1])
    reg_C = int(input_list[2].split(": ")[1])

    program_list = [int(i) for i in input_list[4].split(": ")[1].split(",")]

    return reg_A, reg_B, reg_C, program_list

@cocotb.test()
async def test_project(dut):
    # Parse inputs
    dut._log.info(f'Parsing {FILENAME}...')
    reg_A, reg_B, reg_C, program_list = parse_input(FILENAME)
    dut._log.info(f'Parsed expected initial register values and program:')
    dut._log.info(f'====================================================')
    dut._log.info(f'Register A: {reg_A}')
    dut._log.info(f'Register B: {reg_B}')
    dut._log.info(f'Register C: {reg_C}')
    dut._log.info(f'')
    dut._log.info(f'Program: {program_list}')
    dut._log.info(f'====================================================')

    dut._log.info("Start")

    # Set the clock period to 1 us (1 MHz)
    clock = Clock(dut.clk, 1, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    # TODO: Modify once inputs are actually used
    dut.ui_in.value = 20
    dut.uio_in.value = 30

    # Wait for 400 clock cycles to see the output values
    await ClockCycles(dut.clk, 400)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    # TODO: Check values without revealing actual Advent of Code output
    #       Expected to fail as of now     
    assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
