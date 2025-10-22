"""
Simple verifier for MEL_FBANK test outputs.

Reads:
- `mel_output.txt` produced by the simulation (contains logged mel_spec values)
- `mel_fb_values_hex.txt` contains per-bin weights in hex (pairs or single)

Computes a golden reference by applying the weights to example FFT bins used in the TB
and compares results in Q1.15 units.
"""
import os
import sys
import numpy as np


def read_mel_output(path):
    vals = []
    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            # lines from stim: "<time> <hex>" or VCD prints; capture hex value(s)
            parts = line.split()
            # find first token that looks like hex (contains 0-9A-F)
            for p in parts:
                try:
                    v = int(p, 16)
                    if v >= 0x8000:
                        v -= 0x10000
                    vals.append(v)
                    break
                except Exception:
                    continue
    return np.array(vals, dtype=int)


def q15_to_float(arr):
    return arr / 32768.0


def float_to_q15(x):
    return int(np.round(x * 32768.0))


def main():
    base = os.path.dirname(os.path.abspath(__file__))
    mel_out = os.path.join(base, 'mel_output.txt')
    weight_file = os.path.join(base, '..', 'mel_fb_values_hex.txt')

    if not os.path.exists(mel_out):
        print('mel_output.txt not found. Run the simulation first.')
        return 2

    rtl = read_mel_output(mel_out)
    print(f'Read {len(rtl)} mel outputs from {mel_out}')

    # Build golden by applying example fft_bin = 0x1000 + idx used in TB
    N = 257
    fft_bins = np.array([0x1000 + i for i in range(N)], dtype=int)
    # Read weights if present (optional)
    weights = None
    if os.path.exists(weight_file):
        w = []
        with open(weight_file, 'r') as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) == 0:
                    continue
                # take first hex token
                try:
                    v = int(parts[0], 16)
                    if v >= 0x80000000:
                        v -= 0x100000000
                    w.append(v)
                except Exception:
                    continue
        weights = np.array(w, dtype=int)
        print(f'Read {len(weights)} weights')

    # Simple golden: if weights are present assume mel_spec = fft_bin * (weights[2*i+1] as Q1.15)
    golden = None
    if weights is not None and len(weights) >= 257:
        golden = []
        for i in range(N):
            # if weight stored as 32-bit [re16:im16] take upper 16 as multiplier
            w32 = weights[i]
            w_hi = (w32 >> 16) & 0xFFFF
            if w_hi & 0x8000:
                w_hi -= 0x10000
            # Multiply fft_bin by weight in Q1.15 and shift back
            prod = int(np.round((fft_bins[i] * w_hi) / 32768.0))
            golden.append(prod)
        golden = np.array(golden, dtype=int)
    else:
        print('Weights file not found or too short; skipping golden compare.')

    if golden is not None:
        # Compare first min(len(rtl),len(golden)) points
        m = min(len(rtl), len(golden))
        diffs = np.abs(rtl[:m] - golden[:m])
        max_err = diffs.max()
        print(f'Max error over {m} points: {max_err} (Q1.15 units)')
        print('First 20 diffs:', diffs[:20].tolist())
    else:
        # Just print RTL head
        print('RTL mel outputs (first 32):')
        for i, v in enumerate(rtl[:32]):
            print(f'{i:3d}: {v}')

    return 0


if __name__ == '__main__':
    sys.exit(main())
