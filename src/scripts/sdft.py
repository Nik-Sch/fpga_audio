#!/usr/bin/env python3
import numpy as np
from matplotlib import pyplot

Fs = 24000
N = 512
T = 2048
sinFreq = 600
cosFreq = 10000

def sdft_stage(n: float, oldFreq: complex, oldTime: complex, newTime: complex):
  return np.exp(2j * np.pi * n / N) * (oldFreq  + newTime - oldTime)

def sdft(f: np.ndarray):
  F = np.zeros((T, N), dtype=complex)
  for t in range(T):
    for n in range(N):
      F[t][n] = sdft_stage(
        n,
        F[t - 1][n], # F[-1][n] is zero
        0 if t - N < 0 else f[t - N],
        f[t])

  return [F[-1], F]

def sidft(F: np.ndarray):
  f = np.zeros(T, dtype=complex)
  for t in range(T):
    for n in range(N):
      f[t] += F[t][n]
    f[t] /= N
  return f


t = np.linspace(0, T / Fs, T)
f = np.sin(sinFreq * 2 * np.pi * t) + np.cos(cosFreq * 2 * np.pi * t)
print(np.max(f))
print(np.min(f))

pyplot.subplot(4, 1, 1)
pyplot.plot(t, f)
pyplot.title(f'Real Input Function sin({sinFreq}Hz) + cos({cosFreq}Hz)')
pyplot.xlabel('t in s')
pyplot.grid()

pyplot.subplot(4, 1, 2)
# F = np.fft.fft(f)
F, F_saved = sdft(f)
pyplot.plot(F.real, label='real')
pyplot.plot(F.imag, label='imag')
pyplot.grid()

pyplot.subplot(4, 1, 3)
f = sidft(F_saved)
pyplot.plot(f.real, label='real')
pyplot.grid()

pyplot.subplot(4, 1, 4)
f = np.fft.ifft(F)
pyplot.plot(f.real, label='real')
pyplot.grid()

# pyplot.tight_layout()
# pyplot.savefig('plot.pdf')
pyplot.show()
