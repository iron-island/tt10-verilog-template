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

def get_combo_op(operand, A, B, C):
    if (operand in [0, 1, 2, 3]):
        return operand
    elif (operand == 4):
        return A
    elif (operand == 5):
        return B
    elif (operand == 6):
        return C
    else:
        # Invalid operand
        return 0

def run_instruction(opcode, operand, A, B, C, ip):
    out_valid = False
    program_out = 0
    if (opcode in [0, 6, 7]): # adv, bdv, cdv
        combop = get_combo_op(operand, A, B, C)
        
        result = int(A/(2**combop))
        if (opcode == 0):
            A = result
        elif (opcode == 6):
            B = result
        elif (opcode == 7):
            C = result
    elif (opcode in [1, 4]): # bitwise XOR
        if (opcode == 1):
            B = B ^ operand
        elif (opcode == 4):
            B = B ^ C
    elif (opcode == 2): # modulo 8
        combop = get_combo_op(operand, A, B, C)
        B = combop % 8
    elif (opcode == 5): # out
        combop = get_combo_op(operand, A, B, C)
        program_out = combop % 8
        out_valid = True

    # Update instruction pointer
    if (opcode == 3) and (A > 0):
        ip = operand
    else:
        ip += 2

    return A, B, C, ip, program_out, out_valid

@cocotb.test()
async def test_project(dut):
    # Parse inputs
    print(f'====================================================')
    print(f'Parsing {FILENAME}...')
    reg_A, reg_B, reg_C, program_list = parse_input(FILENAME)
    print(f'Parsed expected initial register values and program:')
    print(f'Register A: {reg_A}')
    print(f'Register B: {reg_B}')
    print(f'Register C: {reg_C}')
    print(f'')
    print(f'Program: {program_list}')

    # Emulate program to get expected output
    print(f'====================================================')
    print(f'Emulating program running to get expected output...')
    ip = 0
    program_out_list = []
    while (ip < len(program_list)):
        opcode  = program_list[ip]
        operand = program_list[ip+1]

        reg_A, reg_B, reg_C, ip, program_out, out_valid = run_instruction(opcode, operand, reg_A, reg_B, reg_C, ip)

        if (out_valid):
            program_out_list.append(program_out)
    print(f'Expected program output: {program_out_list}')
    print(f'====================================================')

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
