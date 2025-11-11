"""
Verify fake_mem testbench output against golden reference
"""

import sys

def read_hex_file(filename):
    """Read hex values from file, ignoring comments"""
    values = []
    try:
        with open(filename, 'r') as f:
            for line in f:
                line = line.strip()
                # Skip comments and empty lines
                if line and not line.startswith('//'):
                    try:
                        val = int(line, 16)
                        values.append(val)
                    except ValueError:
                        continue
        return values
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found!")
        return None

def verify_output(output_file="output.txt", golden_file="golden_output.txt"):
    """
    Compare testbench output against golden reference
    """
    print("="*60)
    print("Verification Script - fake_mem Testbench")
    print("="*60)
    
    # Read files
    print(f"\nReading output file: {output_file}")
    output_data = read_hex_file(output_file)
    
    print(f"Reading golden file: {golden_file}")
    golden_data = read_hex_file(golden_file)
    
    if output_data is None or golden_data is None:
        print("\n[FAIL] Could not read input files!")
        return False
    
    print(f"\n  Output values: {len(output_data)}")
    print(f"  Golden values: {len(golden_data)}")
    
    # Compare
    errors = 0
    matches = 0
    
    print("\n" + "-"*60)
    print("Comparison Results:")
    print("-"*60)
    
    # Compare common length
    compare_len = min(len(output_data), len(golden_data))
    
    for i in range(compare_len):
        if output_data[i] == golden_data[i]:
            matches += 1
            print(f"  [{i:3d}] PASS: Output=0x{output_data[i]:08X}, Golden=0x{golden_data[i]:08X}")
        else:
            errors += 1
            print(f"  [{i:3d}] FAIL: Output=0x{output_data[i]:08X}, Golden=0x{golden_data[i]:08X} (Mismatch!)")
    
    # Check for length mismatch
    if len(output_data) != len(golden_data):
        print(f"\n[WARNING] Length mismatch!")
        print(golden_data)
        print(output_data)
        print(f"  Output: {len(output_data)} values")
        print(f"  Golden: {len(golden_data)} values")
    
    # Summary
    print("\n" + "="*60)
    print("Verification Summary:")
    print("="*60)
    print(f"  Total comparisons: {compare_len}")
    print(f"  Matches: {matches}")
    print(f"  Errors: {errors}")
    
    if errors == 0 and len(output_data) == len(golden_data):
        print("\n  ✓ VERIFICATION PASSED - All outputs match golden reference!")
        print("="*60)
        return True
    else:
        print("\n  ✗ VERIFICATION FAILED - Errors detected!")
        print("="*60)
        return False

if __name__ == "__main__":
    # Run verification
    success = verify_output()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)
