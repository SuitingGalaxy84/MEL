import random
import struct

def generate_random_q15(num_samples=257):
    """
    Generate random Q1.15 format values.
    Q1.15 format: 1 sign bit, 15 fractional bits
    Range: -1.0 to ~0.999969482421875
    16-bit signed integer representation
    """
    random.seed(42)  # For reproducibility, you can change or remove this
    
    q15_values = []
    hex_values = []
    
    for i in range(num_samples):
        # Generate random float between -1.0 and 1.0
        float_val = random.uniform(-1.0, 1.0)
        
        # Convert to Q1.15 (multiply by 2^15 and round)
        q15_int = int(round(float_val * 32768))
        
        # Clamp to valid 16-bit signed range
        q15_int = max(-32768, min(32767, q15_int))
        
        # Convert to unsigned 16-bit representation for hex
        if q15_int < 0:
            q15_unsigned = q15_int & 0xFFFF
        else:
            q15_unsigned = q15_int
        
        q15_values.append(q15_int)
        hex_values.append(q15_unsigned)
    
    return q15_values, hex_values

def write_to_file(hex_values, filename='random_fft_bins_q15.txt'):
    """Write hex values to file, one per line"""
    with open(filename, 'w') as f:
        for val in hex_values:
            f.write(f"{val:04x}\n")
    print(f"Written {len(hex_values)} Q1.15 values to {filename}")

def write_verilog_array(hex_values, filename='random_fft_bins_verilog.txt'):
    """Write as Verilog array initialization"""
    with open(filename, 'w') as f:
        f.write("// Random Q1.15 FFT bin values\n")
        for i, val in enumerate(hex_values):
            f.write(f"16'h{val:04x}")
            if i < len(hex_values) - 1:
                f.write(",\n")
            else:
                f.write("\n")
    print(f"Written Verilog array to {filename}")

if __name__ == "__main__":
    print("Generating random Q1.15 dense sequence...")
    q15_values, hex_values = generate_random_q15(257)
    
    # Write to files
    write_to_file(hex_values, 'random_fft_bins_q15.txt')
    write_verilog_array(hex_values, 'random_fft_bins_verilog.txt')
    
    # Print statistics
    print(f"\nStatistics:")
    print(f"  Number of values: {len(q15_values)}")
    print(f"  Min value: {min(q15_values)} (0x{hex_values[q15_values.index(min(q15_values))]:04x})")
    print(f"  Max value: {max(q15_values)} (0x{hex_values[q15_values.index(max(q15_values))]:04x})")
    print(f"  First 10 values (hex): {[f'0x{v:04x}' for v in hex_values[:10]]}")
