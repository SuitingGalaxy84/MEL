"""
Debug script to understand bit-reversal mapping for 128-point FFT
"""

import numpy as np

def bit_reverse(n, bits):
    """Reverse the bits of n using 'bits' number of bits"""
    result = 0
    for i in range(bits):
        result = (result << 1) | (n & 1)
        n >>= 1
    return result

# For 128-point FFT, we have 7 bits
N = 128
bits = 7

print("Bit-Reversal Mapping for 128-point FFT:")
print("="*60)
print(f"{'Index':<8} {'Binary':<12} {'Rev Binary':<12} {'Rev Index':<8}")
print("-"*60)

# Show first few and important indices
important_indices = list(range(16)) + [64, 127]
for i in sorted(set(important_indices)):
    rev_i = bit_reverse(i, bits)
    bin_i = format(i, f'0{bits}b')
    bin_rev = format(rev_i, f'0{bits}b')
    print(f"{i:<8} {bin_i:<12} {bin_rev:<12} {rev_i:<8}")

print("\n" + "="*60)
print("Analysis for cosine input (1 cycle):")
print("="*60)

# For cosine with 1 cycle, FFT should have peaks at bin 1 and bin N-1=127
print("Input: cos(2*pi*n/128)")
print("  Expected FFT bins with energy: 1 and 127 (in natural order)")
print("  Scaled by 1/128, each peak = 0.5")
print("")
print("After bit reversal:")
print(f"  Bin 1 natural   -> bin {bit_reverse(1, bits)} bit-reversed")
print(f"  Bin 127 natural -> bin {bit_reverse(127, bits)} bit-reversed")
print("")
print("So in RTL output (bit-reversed order):")
print(f"  Output[{bit_reverse(1, bits)}] should have peak")
print(f"  Output[{bit_reverse(127, bits)}] should have peak")

# Read actual output
print("\n" + "="*60)
print("Actual RTL Output (non-zero values):")
print("="*60)

with open('output4.txt', 'r') as f:
    for line in f:
        if '//' in line:
            parts = line.split('//')
            hex_values = parts[0].strip().split()
            index_str = parts[1].strip()
            if len(hex_values) >= 2:
                re_val = hex_values[0]
                im_val = hex_values[1]
                if re_val != '0000' or im_val != '0000':
                    print(f"  Index {index_str}: Real={re_val}, Imag={im_val}")
