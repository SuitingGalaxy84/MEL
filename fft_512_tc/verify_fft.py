"""
FFT512 Verification Script
--------------------------
This script verifies the correctness of the 512-point FFT implementation
by comparing the Verilog output with a golden reference computed in Python.

The FFT uses:
- Radix-2^2 SDF architecture
- Q1.15 fixed-point format
- Scaling by 1/N
- Bit-reversed output order
"""

import numpy as np
import matplotlib.pyplot as plt
from argparse import ArgumentParser
VIVADO = False

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

def float_to_q15(val):
    """Convert float to Q1.15 fixed-point"""
    return int(np.round(val * 32768.0))

def signed_to_hex(val):
    """Convert signed 16-bit value to hex string"""
    if val < 0:
        val = val + 0x10000
    return f"{val:04X}"

def bit_reverse(n, bits):
    """Reverse the bits of n using 'bits' number of bits"""
    result = 0
    for i in range(bits):
        result = (result << 1) | (n & 1)
        n >>= 1
    return result

def read_twiddle_factors():
    """
    Read twiddle factors from Twiddle512.v
    Returns arrays of twiddle factors in Q1.15 format
    """
    # Based on Twiddle512.v comments: wn_re = cos(-2pi*n/512), wn_im = sin(-2pi*n/512)
    # We'll generate all 512 twiddle factors programmatically
    N = 512
    twiddle_re = []
    twiddle_im = []
    
    for n in range(N):
        # w_n = exp(-j * 2 * pi * n / N)
        angle = -2 * np.pi * n / N
        re = np.cos(angle)
        im = np.sin(angle)
        twiddle_re.append(re)
        twiddle_im.append(im)
    
    return np.array(twiddle_re), np.array(twiddle_im)

def compute_fft_golden(input_re, input_im):
    """
    Compute golden reference FFT using numpy
    Input and output in Q1.15 format
    
    NOTE: The README says FFT outputs are in bit-reversed order,
    BUT the testbench's SaveOutputData task re-orders them back to 
    natural order when writing to file! See TB512.v lines 104-109:
        for (n = 0; n < N; n = n + 1) begin
            for (i = 0; i < NN; i = i + 1) m[NN-1-i] = n[i];  // Bit-reverse n
            $fdisplay(fp, "%h  %h  // %d", omem[2*m], omem[2*m+1], n[NN-1:0]);
        end
    So the output file is in NATURAL order, not bit-reversed order.
    """
    N = len(input_re)
    
    # Convert Q1.15 to float
    x_re = q15_to_float(input_re)
    x_im = q15_to_float(input_im)
    
    # Create complex array
    x = x_re + 1j * x_im
    
    # Compute FFT using numpy (natural order output)
    X = np.fft.fft(x)
    
    # Scale by 1/N (as per README)
    X = X / N
    
    # The output file is already in natural order (testbench reverses it back)
    # So we can use X directly
    
    # Convert back to Q1.15
    output_re = np.array([float_to_q15(np.real(x)) for x in X])
    output_im = np.array([float_to_q15(np.imag(x)) for x in X])
    
    return output_re, output_im

def compare_results(golden_re, golden_im, rtl_re, rtl_im, tolerance=2):
    """
    Compare golden reference with RTL output
    tolerance: maximum allowed difference in Q1.15 units
    """
    N = len(golden_re)
    errors = []
    max_error = 0
    
    print("\n" + "="*80)
    print("VERIFICATION RESULTS")
    print("="*80)
    print(f"{'Index':<8} {'Golden (Re,Im)':<25} {'RTL (Re,Im)':<25} {'Error (Re,Im)':<20} {'Status':<10}")
    print("-"*80)
    
    num_shown = 0
    for i in range(N):
        err_re = abs(golden_re[i] - rtl_re[i])
        err_im = abs(golden_im[i] - rtl_im[i])
        total_err = max(err_re, err_im)
        max_error = max(max_error, total_err)
        
        status = "PASS" if total_err <= tolerance else "FAIL"
        
        # Print entries with significant values or errors (limit output)
        if (total_err > tolerance or abs(golden_re[i]) > 10 or abs(golden_im[i]) > 10) and num_shown < 20:
            golden_str = f"{signed_to_hex(golden_re[i])},{signed_to_hex(golden_im[i])}"
            rtl_str = f"{signed_to_hex(rtl_re[i])},{signed_to_hex(rtl_im[i])}"
            err_str = f"{err_re},{err_im}"
            print(f"{i:<8} {golden_str:<25} {rtl_str:<25} {err_str:<20} {status:<10}")
            num_shown += 1
            
        if total_err > tolerance:
            errors.append({
                'index': i,
                'golden': (golden_re[i], golden_im[i]),
                'rtl': (rtl_re[i], rtl_im[i]),
                'error': (err_re, err_im)
            })
    
    print("-"*80)
    print(f"\nTotal points: {N}")
    print(f"Maximum error: {max_error} Q1.15 units ({q15_to_float(max_error):.6f} in float)")
    print(f"Number of mismatches (tolerance={tolerance}): {len(errors)}")
    
    if len(errors) == 0:
        print("\n✓ VERIFICATION PASSED - All outputs match within tolerance!")
    else:
        print(f"\n✗ VERIFICATION FAILED - {len(errors)} mismatches found")
        print("\nFirst 10 errors:")
        for i, err in enumerate(errors[:10]):
            print(f"  Index {err['index']}: Golden={err['golden']}, RTL={err['rtl']}, Error={err['error']}")
    
    return len(errors) == 0, max_error

def plot_comparison(input_re, input_im, golden_re, golden_im, rtl_re, rtl_im):
    import os
    vf_pth = "vf_vivado" if VIVADO else "vf_iverilog"

    """Plot comparison of input, golden, and RTL outputs"""
    N = len(input_re)
    
    fig, axes = plt.subplots(3, 2, figsize=(15, 12))
    
    # Input signal
    axes[0, 0].plot(q15_to_float(input_re), 'g--', linewidth=1, markersize=3)
    axes[0, 0].set_title('Input Signal - Real Part')
    axes[0, 0].set_xlabel('Sample Index')
    axes[0, 0].set_ylabel('Amplitude')
    axes[0, 0].grid(True, alpha=0.3)
    
    axes[0, 1].plot(q15_to_float(input_im), 'g--', linewidth=1, markersize=3)
    axes[0, 1].set_title('Input Signal - Imaginary Part')
    axes[0, 1].set_xlabel('Sample Index')
    axes[0, 1].set_ylabel('Amplitude')
    axes[0, 1].grid(True, alpha=0.3)
    
    # FFT Magnitude
    golden_mag = q15_to_float(golden_re)**2 + q15_to_float(golden_im)**2
    rtl_mag = q15_to_float(rtl_re)**2 + q15_to_float(rtl_im)**2
    
    axes[1, 0].plot(golden_mag, 'b--', label='Golden', linewidth=1, markersize=3)
    axes[1, 0].plot(rtl_mag, 'r--', label='RTL', linewidth=1, markersize=2, alpha=0.7)
    axes[1, 0].set_title('FFT Power Spectrum')
    axes[1, 0].set_xlabel('Frequency Bin')
    axes[1, 0].set_ylabel('Power')
    axes[1, 0].legend()
    axes[1, 0].grid(True, alpha=0.3)
    
    # FFT Phase
    golden_phase = np.angle(q15_to_float(golden_re) + 1j*q15_to_float(golden_im))
    rtl_phase = np.angle(q15_to_float(rtl_re) + 1j*q15_to_float(rtl_im))
    
    axes[1, 1].plot(golden_phase, 'b--', label='Golden', linewidth=1, markersize=3)
    axes[1, 1].plot(rtl_phase, 'r--', label='RTL', linewidth=1, markersize=2, alpha=0.7)
    axes[1, 1].set_title('FFT Phase Spectrum')
    axes[1, 1].set_xlabel('Frequency Bin')
    axes[1, 1].set_ylabel('Phase (radians)')
    axes[1, 1].legend()
    axes[1, 1].grid(True, alpha=0.3)
    
    # Error plots
    error_re = golden_re - rtl_re
    error_im = golden_im - rtl_im
    
    axes[2, 0].stem(error_re, linefmt='b--', markerfmt='b.', basefmt='k-')
    axes[2, 0].set_title('Error - Real Part (Q1.15 units)')
    axes[2, 0].set_xlabel('Sample Index')
    axes[2, 0].set_ylabel('Error')
    axes[2, 0].grid(True, alpha=0.3)
    
    axes[2, 1].stem(error_im, linefmt='b--', markerfmt='b.', basefmt='k-')
    axes[2, 1].set_title('Error - Imaginary Part (Q1.15 units)')
    axes[2, 1].set_xlabel('Sample Index')
    axes[2, 1].set_ylabel('Error')
    axes[2, 1].grid(True, alpha=0.3)
    
    fig_name = f'fft_vf_{args.output_pth.split("/")[-1].replace(".txt", "").replace("output", "")}.png'
    plt.tight_layout()
    plt.savefig(os.path.join(vf_pth, fig_name))
    print(f"\nPlot saved as '{os.path.join(vf_pth, fig_name)}'")
    # plt.show()

def main(input_pth='input2.txt', output_pth='output2.txt'):
    print("="*80)
    print("512-Point FFT Verification")
    print("="*80)
    print("\nConfiguration:")
    print("  - FFT Size: 512 points")
    print("  - Architecture: Radix-2^2 SDF")
    print("  - Format: Q1.15 fixed-point")
    print("  - Scaling: 1/N")
    print("  - Output Order: Bit-reversed")
    print("="*80)
    import generate_data
    generate_data.generate_all_standard_vectors()
    
    # Read input data
    print(f"\n[1/5] Reading input data from {input_pth}...")
    input_re, input_im = read_hex_data(input_pth)
    print(f"  Read {len(input_re)} input samples")
    print(f"  Input range: Real=[{input_re.min()}, {input_re.max()}], Imag=[{input_im.min()}, {input_im.max()}]")
    
    # Read RTL output
    print(f"\n[2/5] Reading RTL output from {output_pth}...")
    rtl_re, rtl_im = read_hex_data(output_pth)
    print(f"  Read {len(rtl_re)} output samples")
    print(f"  Output range: Real=[{rtl_re.min()}, {rtl_re.max()}], Imag=[{rtl_im.min()}, {rtl_im.max()}]")
    
    # Compute golden reference
    print("\n[3/5] Computing golden reference FFT...")
    golden_re, golden_im = compute_fft_golden(input_re, input_im)
    print(f"  Golden range: Real=[{golden_re.min()}, {golden_re.max()}], Imag=[{golden_im.min()}, {golden_im.max()}]")
    
    # Compare results
    print("\n[4/5] Comparing RTL output with golden reference...")
    passed, max_error = compare_results(golden_re, golden_im, rtl_re, rtl_im, tolerance=2)
    
    # Plot results
    print("\n[5/5] Generating comparison plots...")
    plot_comparison(input_re, input_im, golden_re, golden_im, rtl_re, rtl_im)
    
    # Summary
    print("\n" + "="*80)
    print("SUMMARY")
    print("="*80)
    if passed:
        print("✓ FFT implementation verification PASSED")
        print(f"  Maximum error: {max_error} Q1.15 units ({q15_to_float(max_error):.6f} in float)")
    else:
        print("✗ FFT implementation verification FAILED")
        print(f"  Maximum error: {max_error} Q1.15 units ({q15_to_float(max_error):.6f} in float)")
    print("="*80)
    
    return passed

if __name__ == "__main__":
    parser = ArgumentParser(description="Verify 512-point FFT implementation")
    parser.add_argument('--input-pth', type=str, default='input2.txt', help=
                        "Path to input data file (default: input2.txt)")
    parser.add_argument('--output-pth', type=str, default='output2.txt', help=
                        "Path to RTL output data file (default: output2.txt)")
    args = parser.parse_args()
    main(input_pth=args.input_pth, output_pth=args.output_pth)
