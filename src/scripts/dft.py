#!/usr/bin/env python3
import numpy as np
from matplotlib import pyplot

Fs = 24000
N = 512
sinFreq = 600
cosFreq = 10000
t = np.linspace(0, N / Fs, N)
f = np.sin(sinFreq * 2 * np.pi * t) + np.cos(cosFreq * 2 * np.pi * t)

pyplot.subplot(5, 1, 1)
pyplot.plot(t, f)
pyplot.title(f'Real Input Function sin({sinFreq}Hz) + cos({cosFreq}Hz)')
pyplot.xlabel('t in s')
pyplot.grid()

pyplot.subplot(5, 1, 2)
F = np.fft.fft(f)
pyplot.plot(F.real, label='real')
pyplot.plot(F.imag, label='imag')
pyplot.legend(loc='upper left')
pyplot.title(f'Complex Fourier Transform of Input')
pyplot.xlabel('Indices of Result Array')
pyplot.grid()

pyplot.subplot(5, 1, 3)
F_freq = np.fft.fftfreq(N) * Fs
pyplot.plot(F_freq, F.real, label='real')
pyplot.plot(F_freq, F.imag, label='imag')
pyplot.legend(loc='upper left')
pyplot.title(f'Complex Fourier Transform of Input')
pyplot.xlabel('Frequencies')
pyplot.grid()

pyplot.subplot(5, 1, 4)
F[128:384] = 0
pyplot.plot(F_freq, F.real, label='real')
pyplot.plot(F_freq, F.imag, label='imag')
pyplot.legend(loc='upper left')
pyplot.title(f'Complex Fourier Transform, Values > 5kHz set to 0')
pyplot.xlabel('Frequencies')
pyplot.grid()

pyplot.subplot(5, 1, 5)
f_r = np.fft.ifft(F)
pyplot.plot(t, f_r.real)
pyplot.title(f'Inverse Fourier Transform of trimmed Fourier Transform')
pyplot.xlabel('t in s')
pyplot.grid()

# pyplot.tight_layout()
# pyplot.savefig('plot.pdf')
pyplot.show()
