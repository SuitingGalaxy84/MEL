import numpy as np
import argparse

def generate_hann_window(window_len, bit_width=16, output_file=None):
    """
    Generate Hann window coefficients.
    
    Parameters:
    -----------
    window_len : int
        Length of the Hann window
    bit_width : int
        Bit width for fixed-point representation (default: 16)
    output_file : str
        Optional output file path to save coefficients
    
    Returns:
    --------
    numpy.ndarray
        Array of Hann window coefficients
    """
    # Generate Hann window coefficients (normalized 0 to 1)
    n = np.arange(window_len)
    hann_coeffs = 0.5 * (1 - np.cos(2 * np.pi * n / (window_len - 1)))
    
    # Convert to fixed-point representation
    max_value = 2**(bit_width - 1) - 1
    hann_fixed = np.round(hann_coeffs * max_value).astype(int)
    
    # Print coefficients
    print(f"Hann Window Coefficients (Length: {window_len}, Bit Width: {bit_width})")
    print("=" * 60)
    print(f"Floating point range: [{hann_coeffs.min():.6f}, {hann_coeffs.max():.6f}]")
    print(f"Fixed point range: [{hann_fixed.min()}, {hann_fixed.max()}]")
    print()
    
    # Print in different formats
    # print("Decimal format:")
    # for i, coeff in enumerate(hann_fixed):
    #     print(f"  [{i:3d}] = {coeff:6d}")
    
    # print("\nHexadecimal format (for Verilog):")
    for i, coeff in enumerate(hann_fixed):
        hex_val = coeff & ((1 << bit_width) - 1)  # Ensure positive representation
        # print(f"  [{i:3d}] = 16'h{hex_val:04x}")
    
    # Save to file if specified
    if output_file:
        with open(output_file, 'w') as f:
            f.write(f"// Hann Window Coefficients\n")
            f.write(f"// Length: {window_len}\n")
            f.write(f"// Bit Width: {bit_width}\n")
            f.write(f"// Max Value: {max_value}\n\n")
            
            for i, coeff in enumerate(hann_fixed):
                hex_val = coeff & ((1 << bit_width) - 1)
                f.write(f"assign win_coe [{i:3d}] = 16'h{hex_val:04x};\n")
        
        print(f"\nCoefficients saved to: {output_file}")
    
    return hann_coeffs, hann_fixed


def main():
    parser = argparse.ArgumentParser(description='Generate Hann window coefficients')
    parser.add_argument('--window-len', type=int, default=512, help='Length of the Hann window')
    parser.add_argument('--bit-width', type=int, default=16, help='Bit width for fixed-point representation (default: 16)')
    parser.add_argument('--output', type=str, default="HannWin.txt", help='Output file path to save coefficients')
    
    args = parser.parse_args()
    
    if args.window_len <= 0:
        print("Error: window_len must be a positive integer")
        return
    
    generate_hann_window(args.window_len, args.bit_width, args.output)


if __name__ == "__main__":
    main()
