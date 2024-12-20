# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

FILENAME = "./txt/example17.txt"

def parse_input(filename):

    with open(filename) as f:
        input_list = f.read().split("\n")

    init_A = int(input_list[0].split(": ")[1])
    init_B = int(input_list[1].split(": ")[1])
    init_C = int(input_list[2].split(": ")[1])

    program_list = [int(i) for i in input_list[4].split(": ")[1].split(",")]

    return init_A, init_B, init_C, program_list

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

def get_reg_bit(reg, bit):
    # return reg[bit]
    return (reg >> bit) & 1

def update_bit(signal, bitval, bitstart, bitend=None):
    '''
    Wrapper function for updating bits/slices via a read-modify-write sequence
    Ref: https://github.com/cocotb/cocotb/issues/4274#issuecomment-2537077592
    '''
    temp = signal
    if (bitend == None):
        temp[bitstart] = bitval
    else:
        temp[bitstart:bitend] = bitval

    return temp

@cocotb.test()
async def test_project(dut):
    # Parse inputs
    print(f'====================================================')
    print(f'Parsing {FILENAME}...')
    init_A, init_B, init_C, program_list = parse_input(FILENAME)
    print(f'Parsed expected initial register values and program:')
    print(f'Register A: {init_A}')
    print(f'Register B: {init_B}')
    print(f'Register C: {init_C}')
    print(f'')
    print(f'Program: {program_list}')

    # Emulate program to get expected output
    print(f'====================================================')
    print(f'Emulating program running to get expected output...')
    ip = 0
    program_out_list = []
    A = init_A
    B = init_B
    C = init_C
    instruction_counter = 0
    while (ip < len(program_list)):
        opcode  = program_list[ip]
        operand = program_list[ip+1]

        A, B, C, ip, program_out, out_valid = run_instruction(opcode, operand, A, B, C, ip)
        print(f'Instruction {instruction_counter}: A, B, C = {(A, B, C)}, ip = {ip}')
        instruction_counter += 1

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
    dut.ui_in.value = (1 << 3) # init_regs
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut._log.info("Deasserting reset")
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Initialize registers
    dut._log.info("Initializing registers")
    dut.ui_in.value = (1 << 3) # init_regs
    for bit in range(47, -1, -1):
        # Set values to be shifted in to register LSBs
        temp            = update_bit(dut.ui_in.value, get_reg_bit(init_A, bit), 0)
        temp            = update_bit(temp, get_reg_bit(init_B, bit), 1)
        dut.ui_in.value = update_bit(temp, get_reg_bit(init_C, bit), 2)

        # Toggle clock
        await ClockCycles(dut.clk, 1)
    dut.ui_in.value = update_bit(dut.ui_in.value, 0, 3)

    # Input opcodes and operands
    # Loop until halt_ex from uo_out[4] is asserted
    out_counter = 0
    while (not dut.uo_out.value[4]):
        instr_ptr = int(dut.uo_out.value[7:5])

        # TODO: design should handle instructions outside of the program,
        #       though testbench would still be modified since the design
        #       does not know when the program already overflowed
        if (instr_ptr < len(program_list)):
            opcode  = program_list[instr_ptr]
            operand = program_list[instr_ptr+1]
        else:
            opcode = 0
            operand = 0

        # Input opcode and operand
        dut.ui_in.value = (operand << 4) + opcode

        # Toggle clock
        await ClockCycles(dut.clk, 1)

        # Check output value
        if (dut.uo_out.value[3]):
            dut._log.info(f'Design signaled output is valid with index = {out_counter}')
            dut._log.info(f'Expected  = {program_out_list[out_counter]}')
            dut._log.info(f'Actual    = {int(dut.uo_out.value[2:0])}')
            assert dut.uo_out.value[2:0] == program_out_list[out_counter]
            out_counter += 1

    # Check that expected number of outputs matches actual number of outputs
    assert len(program_out_list) == out_counter
