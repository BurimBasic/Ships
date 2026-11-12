#!/usr/bin/env python3
"""Statically check the original SHIPS 8086 DOS COM build (not a DOS emulator)."""
from pathlib import Path
import subprocess
import sys

obj = Path(sys.argv[1]) if len(sys.argv)>1 else Path('build/ships.o')
exe = Path(sys.argv[2]) if len(sys.argv)>2 else Path('dist/SHIPS.COM')
src = Path('src/ships.S').read_text()
code = exe.read_bytes()
assert '.code16' in src and '.arch i8086' in src, '8086 assembler mode required'
assert 0 < len(code) < 57344, f'COM image too big: {len(code)}'
assert code[0] in (0xE9, 0xEB), 'Expected .COM near/short jump startup'
assert b'SHIPS /TEST PASS' in code, 'Expected internal /TEST path'
assert b'GAME OVER' in code and b'HARBOR LOST' in code, 'Missing game-over paths'
# GAS -march i8086 rejects immediate-count shifts, PUSHA/POPA, long conditional
# branches, 32-bit instructions and other unsupported CPU features in source.
run = subprocess.run(['objdump', '-d', '-M', 'intel,i8086', str(obj)],
                     capture_output=True, text=True, check=True)
for line in run.stdout.splitlines():
    try:
        instruction = line.split('\t')[-1].strip().lower()
    except IndexError:
        continue
    assert not instruction.startswith(('pushad', 'popad', 'iretd')), line
print(f'PASS: 8086 assembler, {len(code)}-byte COM, DOS /TEST present')
