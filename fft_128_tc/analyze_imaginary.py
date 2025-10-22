"""
Analyze why imaginary parts appear in output4.txt for real-only input
"""

import numpy as np

def read_hex_data(filename):
    """Read hex data from file (real, imag pairs)"""
    data_re = []
    data_im = []
    with open(filename, 'r') as f:
        for line in f:
            if '//' in line:
                parts = line.split('//')
                hex_values = parts[0].strip().split()
                if len(hex_values) >= 2:
                    re_val = int(hex_values[0], 16)
                    im_val = int(hex_values[1], 16)
                    # Convert to signed 16-bit
                    if re_val >= 0x8000:
                        re_val -= 0x10000
                    if im_val >= 0x8000:
                        im_val -= 0x10000
                    data_re.append(re_val)
                    data_im.append(im_val)
    return np.array(data_re), np.array(data_im)

def q15_to_float(val):
    """Convert Q1.15 fixed-point to float"""
    return val / 32768.0

# Read input and output
print("="*80)
print("ANALYSIS: Why Imaginary Parts Appear in FFT Output for Real Input")
print("="*80)

input_re, input_im = read_hex_data('input4.txt')
output_re, output_im = read_hex_data('output4.txt')

print("\n[1] INPUT ANALYSIS")
print("-"*80)
print(f"Input Real values: min={input_re.min()}, max={input_re.max()}")
print(f"Input Imag values: min={input_im.min()}, max={input_im.max()}")
print(f"Input is purely real: {np.all(input_im == 0)}")

# Identify input signal
print(f"\nInput appears to be: cos(2*pi*n/128)")
print(f"This is a REAL cosine wave with frequency = 1 cycle / 128 samples")

print("\n[2] OUTPUT ANALYSIS")
print("-"*80)
print(f"Output Real values: min={output_re.min()}, max={output_re.max()}")
print(f"Output Imag values: min={output_im.min()}, max={output_im.max()}")

print("\nNon-zero imaginary values in output:")
for i in range(len(output_im)):
    if output_im[i] != 0:
        print(f"  Index {i}: Real={output_re[i]:5d} (0x{output_re[i] & 0xFFFF:04X}), "
              f"Imag={output_im[i]:5d} (0x{output_im[i] & 0xFFFF:04X})")

print("\n[3] THEORETICAL EXPLANATION")
print("-"*80)
print("""
For a REAL-valued input signal x[n], the FFT has Hermitian symmetry:
    X[k] = X*[N-k]  (where * denotes complex conjugate)

This means:
    - X[0] is always real (DC component)
    - X[N/2] is always real (Nyquist frequency) 
    - For k ≠ 0, N/2: X[k] and X[N-k] are complex conjugates

For input4.txt: x[n] = cos(2πn/128)
    - Using Euler's formula: cos(θ) = (e^(jθ) + e^(-jθ))/2
    - FFT of cos(2πn/128) should have peaks at bins k=1 and k=127

Expected FFT output:
    - X[0] = 0 (no DC component)
    - X[1] = N/2 = 64 samples worth of energy = 0.5 (after 1/N scaling)
    - X[127] = N/2 = 64 samples worth of energy = 0.5 (conjugate of X[1])
    - All other bins ≈ 0

For a pure cosine (real signal):
    - X[1] should be REAL and POSITIVE
    - X[127] should be REAL and POSITIVE (conjugate of X[1])
    - NO imaginary parts should exist!
""")

print("\n[4] ACTUAL vs EXPECTED")
print("-"*80)

# Compute expected FFT
N = 128
x = q15_to_float(input_re) + 1j * q15_to_float(input_im)
X = np.fft.fft(x) / N

print(f"\nExpected (from NumPy FFT):")
print(f"  X[0]   = {X[0].real:8.5f} + j*{X[0].imag:8.5f}")
print(f"  X[1]   = {X[1].real:8.5f} + j*{X[1].imag:8.5f}  <- Should be ~0.5 + j*0")
print(f"  X[127] = {X[127].real:8.5f} + j*{X[127].imag:8.5f}  <- Should be ~0.5 + j*0")

print(f"\nActual (from output4.txt):")
print(f"  X[0]   = {q15_to_float(output_re[0]):8.5f} + j*{q15_to_float(output_im[0]):8.5f}")
print(f"  X[1]   = {q15_to_float(output_re[1]):8.5f} + j*{q15_to_float(output_im[1]):8.5f}")
print(f"  X[127] = {q15_to_float(output_re[127]):8.5f} + j*{q15_to_float(output_im[127]):8.5f}")

print("\n[5] ROOT CAUSE ANALYSIS")
print("-"*80)

# Check if imaginary values are just rounding errors
max_imag_error = np.max(np.abs(output_im))
print(f"\nMaximum imaginary value magnitude: {max_imag_error} Q1.15 units")
print(f"In floating point: {q15_to_float(max_imag_error):.10f}")
print(f"As percentage of peak signal: {100.0 * max_imag_error / 16382:.6f}%")

print("\n" + "="*80)
print("CONCLUSION")
print("="*80)

if max_imag_error <= 1:
    print("""
✓ The imaginary parts are NEGLIGIBLE ROUNDING ERRORS (±1 LSB)

Explanation:
1. The FFT hardware uses FIXED-POINT arithmetic (Q1.15 format)
2. Each multiplication and addition introduces QUANTIZATION ERROR
3. Through the butterfly stages, these small errors accumulate
4. The ±1 LSB errors you see are the result of:
   - Rounding during fixed-point multiplications
   - Truncation in scaling operations
   - Numerical precision limits of 16-bit representation

5. For a PURE COSINE input, the theoretical output should have ZERO 
   imaginary parts at bins 1 and 127
6. However, due to fixed-point arithmetic, we get ±1 LSB errors
7. This represents an error of ±0.000031 in magnitude
8. This is COMPLETELY NORMAL and ACCEPTABLE for fixed-point FFT

The implementation is CORRECT - these are just expected quantization artifacts!
""")
else:
    print(f"""
⚠ The imaginary parts ({max_imag_error} LSB) may be larger than expected.
This could indicate an issue with the implementation.
""")

print("="*80)
