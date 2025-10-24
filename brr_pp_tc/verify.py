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

def generate_data(input_file="input.txt", golden_file="golden_output.txt", frames=2):
    """
    Generates input data for the testbench and the golden output file.
    """
    print(f"Generating {frames} frames of data...")

    # Data in natural order
    natural_re = np.arange(frames * N, dtype=np.uint16)
    natural_im = np.arange(frames * N, 0, -1, dtype=np.uint16) - 1
    
    # Create bit-reversed data for the input file
    with open(input_file, "w") as f_in:
        for frame in range(frames):
            for i in range(N):
                # The DUT expects bit-reversed input, so we provide it in that order
                br_i = bit_reverse(i, BITS)
                idx = frame * N + br_i
                f_in.write(f"{natural_re[idx]:04x} {natural_im[idx]:04x}\n")

    print(f"Generated '{input_file}' for simulation input.")

    # The golden output should be the natural order data, with latency
    with open(golden_file, "w") as f_gold:
        # The DUT has a latency of N cycles. The first frame is readable after the second starts writing.
        # The output is one frame delayed.
        for i in range(N):
             f_gold.write(f"{natural_re[i]} {natural_im[i]}\n")

    print(f"Generated '{golden_file}' for verification.")


def verify_output(output_file="output.txt", golden_file="golden_output.txt"):
    """
    Compares the simulation output with the golden output.
    """
    print("Verifying output...")
    try:
        with open(output_file, "r") as f_out, open(golden_file, "r") as f_gold:
            sim_lines = [line.strip() for line in f_out if line.strip()]
            golden_lines = [line.strip() for line in f_gold if line.strip()]

            if len(sim_lines) != len(golden_lines):
                print(f"Verification FAILED: Mismatch in number of lines.")
                print(f"Got {len(sim_lines)} lines, expected {len(golden_lines)}.")
                return False

            errors = 0
            for i, (sim_line, golden_line) in enumerate(zip(sim_lines, golden_lines)):
                if sim_line != golden_line:
                    errors += 1
                    if errors < 10: # Print first few errors
                        print(f"Mismatch at line {i+1}:")
                        print(f"  Got:      '{sim_line}'")
                        print(f"  Expected: '{golden_line}'")

            if errors == 0:
                print("Verification PASSED: Output matches golden file.")
                return True
            else:
                print(f"Verification FAILED: Found {errors} mismatched lines.")
                return False

    except FileNotFoundError as e:
        print(f"Error: {e}. Make sure simulation has been run and files exist.")
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
