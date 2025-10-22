#!/usr/bin/env python3
"""
Encode mel filterbank non-zero index file into a 257x2 toggle-bit encoding.

Algorithm:
- Maintain two slots (left=0, right=1). Start bits [0,1] and prev_cols [0,1].
- For each row (top to bottom) parse up to two tuples (filter,col) in file order.
- If two tuples: choose the assignment to left/right that maximizes matches to prev_cols (keeps continuity).
- If one tuple: assign it to the slot whose prev_col is nearest (preferring exact match).
- Toggle a slot's bit only when its assigned column changes from prev_cols[slot].

Output: writes `encoded_mel_fb.txt` with 257 rows, each row `bit_left,bit_right`.
"""
import os
import re
import sys
import numpy as np

def get_nz_idx(mat, out_path):

    num_filters, num_bins = mat.shape
    with open(out_path, 'w') as f:
        for i in range(num_filters):
            for j in range(num_bins):
                if mat[i, j] == 0.0:
                    f.write("x\t")
                else:
                    f.write(f"({i},{j})\t")
            f.write("\n")

    f.close()

def parse_line(line):
    # split on tabs (file uses tabs), filter empty
    parts = re.split(r"\t+", line.strip())
    tuples = []
    for p in parts:
        p = p.strip()
        if p.startswith("(") and p.endswith(")"):
            # expect format (filter,col)
            try:
                inside = p[1:-1]
                a, b = inside.split(",")
                f = int(a.strip())
                c = int(b.strip())
                tuples.append((f, c))
            except Exception:
                # ignore unparsable
                continue
    return tuples


def encode_rows(lines, nrows=257):
    prev_cols = [0, 1]
    bits = [0, 1]
    out = []
    mapping = []  # Track (filter, col) pairs for each slot at each row

    for i in range(min(nrows, len(lines))):
        line = lines[i]
        tuples = parse_line(line)
        cols = [c for (_, c) in tuples]

        assigned = [None, None]

        if len(cols) == 0:
            # no change
            pass
        elif len(cols) == 1:
            c = cols[0]
            # prefer exact match, otherwise nearest prev_col
            if c == prev_cols[0] and c != prev_cols[1]:
                slot = 0
            elif c == prev_cols[1] and c != prev_cols[0]:
                slot = 1
            else:
                # choose slot with minimal distance to maintain continuity
                d0 = abs(c - prev_cols[0])
                d1 = abs(c - prev_cols[1])
                slot = 0 if d0 <= d1 else 1
            assigned[slot] = c
        else:
            # 2 or more tuples: take first two in appearance order
            c1, c2 = cols[0], cols[1]
            # permutation 1: first->slot0, second->slot1
            m1 = (1 if c1 == prev_cols[0] else 0) + (1 if c2 == prev_cols[1] else 0)
            # permutation 2: first->slot1, second->slot0
            m2 = (1 if c1 == prev_cols[1] else 0) + (1 if c2 == prev_cols[0] else 0)
            if m1 > m2:
                assigned = [c1, c2]
            elif m2 > m1:
                assigned = [c2, c1]
            else:
                # tie: keep appearance order -> assign first to left, second to right
                assigned = [c1, c2]

        # apply assignments and toggle bits if column changed
        # Special handling: if a slot becomes None (no more data), invert its bit
        for s in (0, 1):
            if assigned[s] is not None:
                if assigned[s] != prev_cols[s]:
                    bits[s] ^= 1
                    prev_cols[s] = assigned[s]
                else:
                    # remains the same
                    prev_cols[s] = assigned[s]

        # Find the (filter, col) pairs for current slots
        filter_col_left = None
        filter_col_right = None
        for filt, col in tuples:
            if col == prev_cols[0]:
                filter_col_left = (filt, col)
            if col == prev_cols[1]:
                filter_col_right = (filt, col)
        
        # If a slot transitions to None (end of data for that MAC), toggle its bit
        if filter_col_left is None and i > 0 and mapping[i-1][0] is not None:
            bits[0] ^= 1
        if filter_col_right is None and i > 0 and mapping[i-1][1] is not None:
            bits[1] ^= 1
        
        out.append((bits[0], bits[1]))
        mapping.append((filter_col_left, filter_col_right))

    # If fewer than nrows processed, extend remaining rows with current bits
    while len(out) < nrows:
        out.append((bits[0], bits[1]))
        mapping.append((None, None))

    return out, mapping


def float_to_q15(value):
    """Convert float to Q1.15 fixed-point format (16-bit signed)"""
    # Q1.15 format: 1 sign bit, 15 fractional bits
    # Range: [-1, 1) with resolution of 1/32768
    q15_value = int(round(value * 32768.0))
    
    # Clamp to 16-bit signed range
    if q15_value > 32767:
        q15_value = 32767
    elif q15_value < -32768:
        q15_value = -32768
    
    # Convert to unsigned 16-bit representation (two's complement)
    if q15_value < 0:
        q15_value = q15_value & 0xFFFF
    
    return q15_value


def generate_q15_hex_values(mat, mapping):
    """
    Generate Q1.15 hex values for the mapped indices.
    Concatenate left (16-bit) and right (16-bit) into one 32-bit hex value.
    Format: [left_16bit][right_16bit]
    """
    hex_values = []
    
    for left_idx, right_idx in mapping:
        # Get left value
        if left_idx is not None:
            filt_l, col_l = left_idx
            if filt_l < mat.shape[0] and col_l < mat.shape[1]:
                left_val = mat[filt_l, col_l]
            else:
                left_val = 0.0
        else:
            left_val = 0.0
        
        # Get right value
        if right_idx is not None:
            filt_r, col_r = right_idx
            if filt_r < mat.shape[0] and col_r < mat.shape[1]:
                right_val = mat[filt_r, col_r]
            else:
                right_val = 0.0
        else:
            right_val = 0.0
        
        # Convert to Q1.15
        left_q15 = float_to_q15(left_val)
        right_q15 = float_to_q15(right_val)
        
        # Concatenate: left in upper 16 bits, right in lower 16 bits
        combined_32bit = (left_q15 << 16) | right_q15
        
        hex_values.append(combined_32bit)
    
    return hex_values


def main():
    base = os.path.dirname(os.path.abspath(__file__))
    in_path = os.path.join(base, 'D:\\Desktop\\PG Repo\\MEL\\mel_fbank_tc\\convert\\mel_fb_float.txt')
    mac_bits_out_path = os.path.join(base, 'D:\\Desktop\\PG Repo\\MEL\\mel_fbank_tc\\convert\\mac_bits.txt')
    nz_idx_out_path = os.path.join(base, 'D:\\Desktop\\PG Repo\\MEL\\mel_fbank_tc\\convert\\mel_fb_idx.txt')
    mapping_out_path = os.path.join(base, 'D:\\Desktop\\PG Repo\\MEL\\mel_fbank_tc\\convert\\mac_pos.txt')
    q15_hex_out_path = os.path.join(base, 'D:\\Desktop\\PG Repo\\MEL\\mel_fbank_tc\\convert\\mac_q15_hex.txt')

    mat = np.loadtxt(in_path, dtype=float)
    get_nz_idx(mat, nz_idx_out_path)

    if not os.path.exists(nz_idx_out_path):
        print(f'Index file not found: {nz_idx_out_path}', file=sys.stderr)
        sys.exit(2)

    # Read from the generated index file instead
    with open(nz_idx_out_path, 'r', encoding='utf-8') as f:
        lines = [l.rstrip('\n') for l in f if l.strip() != '']

    encoded, mapping = encode_rows(lines, nrows=257)

    with open(mac_bits_out_path, 'w', encoding='utf-8') as f:
        for a, b in encoded:
            f.write(f"{a}{b}\n")

    # Save the mapping: mac_bit => non-zero index
    with open(mapping_out_path, 'w', encoding='utf-8') as f:
        for left_idx, right_idx in mapping:
            left_str = f"({left_idx[0]},{left_idx[1]})" if left_idx is not None else "None"
            right_str = f"({right_idx[0]},{right_idx[1]})" if right_idx is not None else "None"
            f.write(f"{left_str}\t{right_str}\n")

    # Generate Q1.15 hex values
    hex_values = generate_q15_hex_values(mat, mapping)
    
    with open(q15_hex_out_path, 'w', encoding='utf-8') as f:
        for hex_val in hex_values:
            f.write(f"{hex_val:08X}\n")

    # print first 32 rows as a quick check
    print('Wrote', mac_bits_out_path)
    print('Wrote', mapping_out_path)
    print('Wrote', q15_hex_out_path)
    print('\nFirst 32 encoded rows:')
    for i, (a, b) in enumerate(encoded[:32]):
        left_idx, right_idx = mapping[i]
        left_str = f"({left_idx[0]},{left_idx[1]})" if left_idx is not None else "None"
        right_str = f"({right_idx[0]},{right_idx[1]})" if right_idx is not None else "None"
        hex_val = hex_values[i]
        print(f'{i:3d}: {a},{b}  =>  {left_str:12s} {right_str:12s}  =>  0x{hex_val:08X}')


if __name__ == '__main__':
    main()
