#!/usr/bin/env python3
import sys
import numpy as np
import struct

if len(sys.argv) != 3:
  print(f"usage: {sys.argv[0]} N <file>.coe")
  exit(1)

n = int(sys.argv[1])
coeFile = open(sys.argv[2], 'w')

coeFile.write('memory_initialization_radix=16;\n')
coeFile.write('memory_initialization_vector=\n')

def f2h(f):
    return f"{struct.unpack('<I', struct.pack('<f', f))[0]:08x}"

r = []
c = []
for i in range(n):
  res = np.exp(2j * np.pi * i / n)
  coeFile.write(f2h(res.real))
  coeFile.write(f2h(res.imag))
  r.append(res.real)
  c.append(res.imag)
  if i == n - 1:
    coeFile.write(';\n')
  else:
    coeFile.write(',\n')

print(np.min(r))
print(np.min(c))
