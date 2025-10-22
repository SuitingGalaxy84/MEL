"""
Comprehensive FFT Verification for all test vectors
"""

import subprocess
import os

def verify_test_vector(input_file, output_file):
    """Verify a single test vector pair"""
    print(f"\nVerifying {input_file} -> {output_file}")
    print("="*80)
    
    # Create a temporary verification script
    script = f"""
import numpy as np
exec(open('verify_fft.py').read().replace("'input4.txt'", "'{input_file}'").replace("'output4.txt'", "'{output_file}'"))
"""
    
    # Instead, we'll import and call the functions
    import sys
    sys.path.insert(0, os.getcwd())
    from verify_fft import read_hex_data, compute_fft_golden, compare_results
    
    # Read data
    input_re, input_im = read_hex_data(input_file)
    rtl_re, rtl_im = read_hex_data(output_file)
    
    # Compute golden
    golden_re, golden_im = compute_fft_golden(input_re, input_im)
    
    # Compare
    passed, max_error = compare_results(golden_re, golden_im, rtl_re, rtl_im, tolerance=2)
    
    return passed, max_error

def main():
    print("="*80)
    print("COMPREHENSIVE FFT128 VERIFICATION")
    print("="*80)
    
    test_vectors = [
        ('input4.txt', 'output4.txt'),
        ('input5.txt', 'output5.txt'),
    ]
    
    all_passed = True
    results = []
    
    for input_file, output_file in test_vectors:
        if os.path.exists(input_file) and os.path.exists(output_file):
            passed, max_error = verify_test_vector(input_file, output_file)
            results.append((input_file, output_file, passed, max_error))
            all_passed = all_passed and passed
        else:
            print(f"\nSkipping {input_file}/{output_file} - files not found")
    
    # Final summary
    print("\n" + "="*80)
    print("FINAL SUMMARY")
    print("="*80)
    print(f"{'Test Vector':<40} {'Status':<15} {'Max Error (Q1.15)':<20}")
    print("-"*80)
    
    for input_file, output_file, passed, max_error in results:
        test_name = f"{input_file} -> {output_file}"
        status = "✓ PASSED" if passed else "✗ FAILED"
        print(f"{test_name:<40} {status:<15} {max_error:<20}")
    
    print("="*80)
    if all_passed:
        print("✓✓✓ ALL TESTS PASSED ✓✓✓")
    else:
        print("✗✗✗ SOME TESTS FAILED ✗✗✗")
    print("="*80)

if __name__ == "__main__":
    main()
