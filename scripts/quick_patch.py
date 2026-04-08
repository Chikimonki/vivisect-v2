#!/usr/bin/env python3
# ~/vivisect/scripts/quick_patch.py
# Patch patient_zero to always authenticate

import lief

binary = lief.parse("targets/patient_zero")

# Find the authenticate function by looking for the comparison pattern
text = binary.get_section(".text")
code = bytearray(text.content)

# Find 'test eax, eax' followed by 'je' (the authentication branch)
# test eax, eax = 85 C0
# je short = 74 XX
import re
pattern = re.compile(b'\\x85\\xc0\\x74')
for m in pattern.finditer(bytes(code)):
    offset = m.start()
    print(f"[*] Found auth branch at .text+0x{offset:X}")
    # Patch 'je' (0x74) to 'jmp' (0xEB) — always jump... 
    # or NOP the je to never jump
    # Let's NOP: 74 XX -> 90 90
    code[offset + 2] = 0x90  # NOP over the je opcode
    code[offset + 3] = 0x90  # NOP over the offset
    print(f"[+] Patched: je -> NOP NOP")

text.content = list(code)
binary.write("targets/patient_zero_patched")
print("[+] Written: targets/patient_zero_patched")
