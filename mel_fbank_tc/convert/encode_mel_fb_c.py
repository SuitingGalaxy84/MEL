#!/usr/bin/env python3
"""
Generates a test matrix with a controllable number of non-zero values per column,
determined by the NUM_MACS parameter. This is not a real mel filterbank but is
structurally similar for testing encoding algorithms.
"""
import numpy as np
import os

def generate_test_matrix(
    num_macs,
    num_filters=160,
    num_bins=257
):
    """
    Generates a matrix with overlapping triangular filters to ensure that at least
    one column has `num_macs` non-zero entries.
    
    The generated file is named 'test_matrix_macs_{num_macs}.txt'.
    """
    output_file = f'test_matrix_macs_{num_macs}.txt'
    mat = np.zeros((num_filters, num_bins))

    # These two parameters control the overlap.
    # By making the width a multiple of the spacing, we guarantee max overlap.
    filter_spacing = 3
    filter_width = filter_spacing * num_macs

    if filter_width <= 1:
        filter_width = 2  # Ensure width is at least 2 for a triangle shape

    print(f"Generating test matrix for NUM_MACS={num_macs}...")

    for i in range(num_filters):
        start_bin = i * filter_spacing
        peak_bin = start_bin + (filter_width // 2)
        end_bin = start_bin + filter_width

        # Create one triangular filter
        for j in range(start_bin, end_bin):
            if j >= num_bins:
                continue

            value = 0.0
            # Rising edge of the triangle
            if j <= peak_bin:
                if peak_bin > start_bin:
                    # Linearly ramp up from 0 to 1
                    value = (j - start_bin) / (peak_bin - start_bin)
            # Falling edge of the triangle
            else:
                if end_bin > peak_bin:
                    # Linearly ramp down from 1 to 0
                    value = 1.0 - (j - peak_bin) / (end_bin - peak_bin)
            
            mat[i, j] = max(0.0, value)

    # Save the matrix to a file
    np.savetxt(output_file, mat, fmt='%.8f', delimiter='\t')

    # Analyze and report the actual maximum overlap for verification
    non_zero_per_col = np.count_nonzero(mat, axis=0)
    max_overlap = np.max(non_zero_per_col)
    
    print(f"Successfully generated '{output_file}'.")
    print(f"  - Target max overlap (NUM_MACS): {num_macs}")
    print(f"  - Actual max overlap in matrix: {max_overlap}\n")

if __name__ == '__main__':
    # Generate files for NUM_MACS values of 2, 4, and 8.
    # You can edit this list to generate files for other values.
    mac_values_to_generate = [2]
    
    for macs in mac_values_to_generate:
        generate_test_matrix(num_macs=macs)
