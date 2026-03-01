import re

OPCODES = {
    'add': 0b000000, 'sub': 0b000001, 'mul': 0b000010,
    'fma': 0b000011, 'relu': 0b000100, 'ld': 0b000101,
    'st': 0b000110, 'const': 0b000111, 'or': 0b001010,
    'tid': 0b001110, 'ret': 0b111111
}

reg_map = {}
next_reg_idx = 0

def get_reg_code(ptx_reg):
    global next_reg_idx
    clean_reg = re.sub(r'[^%a-zA-Z0-9]', '', ptx_reg)
    if clean_reg not in reg_map:
        if next_reg_idx > 15:
            raise ValueError(f"one instruction exceed 16 registers！problem is on：{clean_reg}")
        reg_map[clean_reg] = next_reg_idx
        next_reg_idx += 1
    return reg_map[clean_reg]

def parse_ptx_to_hex(input_file, output_file):
    global reg_map, next_reg_idx

    with open(input_file, 'r') as f_in, open(output_file, 'w') as f_out:
        for line in f_in:
            line = line.strip()

            if line.startswith('.visible .entry') or line.startswith('.entry') or line.startswith('.func'):
                reg_map.clear()
                next_reg_idx = 0
                f_out.write(f"\n// =========================================\n")
                f_out.write(f"// 🚀 {line}\n")
                f_out.write(f"// =========================================\n")
                continue

            if not line or line.startswith('//') or line.startswith('.'):
                continue

            match = re.match(r'^([a-z]+)(?:\.[a-z0-9]+)*\s+(.*);', line)
            if not match:
                continue

            base_inst = match.group(1)
            operands_str = match.group(2)

            opcode_val, rd_val, rs1_val, rs2_val, rs3_val = 0, 0, 0, 0, 0
            func_val, imm_val = 0b000000, 0b0000

            ops = [op.strip() for op in operands_str.split(',')]

            if base_inst in ['mov', 'cvt']:
                if len(ops) >= 2:
                    rd_str = ops[0]
                    src_str = ops[1]
                    rd_val = get_reg_code(rd_str)

                    if '%tid' in src_str:
                        opcode_val = OPCODES['tid']
                    elif not src_str.startswith('%') and not src_str.startswith('['):
                        opcode_val = OPCODES['const']
                        try:
                            imm_val = int(src_str) & 0b1111
                        except ValueError:
                            imm_val = 0
                    else:
                        opcode_val = OPCODES['or']
                        rs1_val = get_reg_code(src_str)
                        rs2_val = rs1_val

            elif base_inst in OPCODES:
                opcode_val = OPCODES[base_inst]
                regs = re.findall(r'%[a-zA-Z0-9]+', operands_str)

                if base_inst == 'fma' and len(regs) >= 4:
                    rd_val = get_reg_code(regs[0])
                    rs1_val = get_reg_code(regs[1])
                    rs2_val = get_reg_code(regs[2])
                    rs3_val = get_reg_code(regs[3])
                elif base_inst in ['add', 'sub', 'mul'] and len(regs) >= 3:
                    rd_val = get_reg_code(regs[0])
                    rs1_val = get_reg_code(regs[1])
                    rs2_val = get_reg_code(regs[2])
                elif base_inst == 'ld' and len(regs) >= 2:
                    rd_val = get_reg_code(regs[0])
                    rs1_val = get_reg_code(regs[1])
                elif base_inst == 'st' and len(regs) >= 2:
                    rs1_val = get_reg_code(regs[0])
                    rs2_val = get_reg_code(regs[1])
            else:
                continue

            machine_code = (
                f"{opcode_val:06b}{rd_val:04b}{rs1_val:04b}{rs2_val:04b}"
                f"{rs3_val:04b}{func_val:06b}{imm_val:04b}"
            )
            f_out.write(f"{machine_code} // {line}\n")

    print(f"🎉 translation finished！already generated {output_file}")

parse_ptx_to_hex('kernel.ptx', 'gpu_program.hex')
