import numpy as np
import sys

N = 128
BITS = 7

def bit_reverse(n, bits):
    """Reverses the bits of a number."""
    result = 0
    for i in range(bits):
        if (n >> i) & 1:
            result |= 1 << (bits - 1 - i)
    return result

def generate_data(golden_file="golden_output.txt", frames=2):
    """
    Generates the golden output file for verification.
    
    The testbench sends sequential data:
    - Frame 0: di_re = [0, 1, 2, ..., 127], di_im = 0
    - Frame 1: di_re = [128, 129, ..., 255], di_im = 0
    
    The module should output this in NATURAL ORDER (unchanged sequence)
    because the bit-reversal reordering happens internally via addressing.
    """
    print(f"Generating {frames} frames of golden data (natural order)...")

    with open("frame_input.txt", "w") as f_in:
        for frame in range(frames):

            # Expected output: natural order (same as input sequence)
            for i in range(N):
                re_val = i + frame * N  # ✅ Natural order
                im_val = 0
                f_in.write(f"{re_val} {im_val}\n")
    f_in.close()

    with open(golden_file, "w") as f_gold:
        for frame in range(frames):
            for i in range(N):
                #bit_rev_i = bit_reverse(i, BITS)
                re_val = bit_reverse(i, BITS) + frame * N  
                im_val = 0
                f_gold.write(f"{re_val} {im_val}\n")
    f_gold.close()
    print(f"Generated '{golden_file}' for verification.")
    print(f"Expected output: sequential values in natural order")


def verify_output(output_file="output.txt", golden_file="golden_output.txt"):
    """
    Compares the simulation output with the golden output.
    """
    print("--- Verifying output ---")
    try:
        with open(output_file, "r") as f_out, open(golden_file, "r") as f_gold:
            sim_lines = [line.strip() for line in f_out if line.strip()]
            golden_lines = [line.strip() for line in f_gold if line.strip()]
            
            if len(sim_lines) != len(golden_lines):
                print(f"❌ Verification FAILED: Mismatch in number of lines.")
                print(f"   Got {len(sim_lines)} lines, expected {len(golden_lines)}.")
                return False

            errors = 0
            for i, (sim_line, golden_line) in enumerate(zip(sim_lines, golden_lines)):
                if sim_line != golden_line:
                    errors += 1
                    if errors <= 10:  # Print first 10 errors
                        print(f"   Mismatch at line {i+1}:")
                        print(f"     Got:      '{sim_line}'")
                        print(f"     Expected: '{golden_line}'")

            if errors == 0:
                print("✅ Verification PASSED: Output matches golden file.")
                return True
            else:
                print(f"❌ Verification FAILED: Found {errors} mismatched lines.")
                return False

    except FileNotFoundError as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == "generate":
            generate_data()
        elif sys.argv[1] == "verify":
            verify_output()
        else:
            print(f"Unknown command: {sys.argv[1]}")
            print("Usage: python verify.py [generate|verify]")
    else:
        print("Usage: python verify.py [generate|verify]")
