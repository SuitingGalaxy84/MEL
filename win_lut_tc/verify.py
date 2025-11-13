import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import get_window

# Parameters
WIDTH = 16
N_FFT = 512
WIN_LEN = 480
HOP_LEN = 160
Q_FORMAT = 15

def q15_to_float(val):
    """Convert Q0.15 fixed-point to floating point"""
    # Handle negative numbers in two's complement
    if val < 0:
        val = (1 << 16) + val
    if val & 0x8000:
        val = val - 0x10000
    return val / (2**Q_FORMAT)

def float_to_q15(val):
    """Convert floating point to Q0.15 fixed-point"""
    max_val = 2**15 - 1
    min_val = -2**15
    fixed = int(round(val * (2**Q_FORMAT)))
    fixed = max(min_val, min(max_val, fixed))
    return fixed

def load_hann_window():
    """Load Hann window coefficients from HannWin.v or generate them"""
    # Generate Hann window using scipy (should match the LUT)
    window = get_window('hann', N_FFT)
    return window

def apply_window_golden(input_re, input_im, window):
    """
    Apply windowing operation - Golden reference model
    
    The Window_lut module:
    1. Accumulates WIN_LEN samples in a circular buffer
    2. Every N_FFT cycles, outputs a windowed frame:
       - First WIN_LEN samples are multiplied by window coefficients
       - Remaining (N_FFT - WIN_LEN) samples are zero-padded
    3. The read pointer moves back by (WIN_LEN - HOP_LEN) after each frame
    """
    num_samples = len(input_re)
    
    # We need at least WIN_LEN samples to produce the first frame
    if num_samples < WIN_LEN:
        print(f"Warning: Not enough samples ({num_samples}) for first frame (need {WIN_LEN})")
        return [], []
    
    # Calculate how many complete frames we can generate
    # First frame needs WIN_LEN samples, each subsequent frame needs HOP_LEN more
    num_frames = 1 + max(0, (num_samples - WIN_LEN) // HOP_LEN)
    
    print(f"Input samples: {num_samples}")
    print(f"Expected frames: {num_frames}")
    
    output_frames_re = []
    output_frames_im = []
    
    for frame_idx in range(num_frames):
        # Calculate the starting position for this frame
        frame_start = frame_idx * HOP_LEN
        frame_end = frame_start + WIN_LEN
        
        if frame_end > num_samples:
            print(f"Frame {frame_idx}: Not enough samples (need {frame_end}, have {num_samples})")
            break
        
        print(f"Frame {frame_idx}: samples [{frame_start}:{frame_end})")
        
        # Extract the frame data
        frame_re = input_re[frame_start:frame_end]
        frame_im = input_im[frame_start:frame_end]
        
        # Apply window (first WIN_LEN coefficients)
        windowed_re = frame_re * window[:WIN_LEN]
        windowed_im = frame_im * window[:WIN_LEN]
        
        # Zero-pad to N_FFT length
        padded_re = np.zeros(N_FFT)
        padded_im = np.zeros(N_FFT)
        padded_re[:WIN_LEN] = windowed_re
        padded_im[:WIN_LEN] = windowed_im
        
        output_frames_re.append(padded_re)
        output_frames_im.append(padded_im)
    
    return output_frames_re, output_frames_im

def main():
    print("=" * 70)
    print("Window LUT Testbench - Verification Script")
    print("=" * 70)
    
    # Load input data (floating point reference)
    try:
        data = np.load('input_float.npz')
        input_re_float = data['signal_re']
        input_im_float = data['signal_im']
        print(f"Loaded {len(input_re_float)} input samples from input_float.npz")
    except:
        print("Error: Could not load input_float.npz")
        print("Please run generate_input.py first")
        return
    
    # Load Hann window
    hann_window = load_hann_window()
    
    # Generate golden reference
    print("\nGenerating golden reference...")
    golden_frames_re, golden_frames_im = apply_window_golden(
        input_re_float, input_im_float, hann_window)
    
    num_golden_frames = len(golden_frames_re)
    print(f"Generated {num_golden_frames} golden reference frames")
    
    # Save golden output
    with open('golden_output.txt', 'w') as f:
        for frame_idx in range(num_golden_frames):
            for i in range(N_FFT):
                re_q15 = float_to_q15(golden_frames_re[frame_idx][i])
                im_q15 = float_to_q15(golden_frames_im[frame_idx][i])
                # Write as hexadecimal (16-bit unsigned representation)
                f.write(f"{re_q15 & 0xFFFF:04x} {im_q15 & 0xFFFF:04x}\n")
    print(f"Golden reference written to: golden_output.txt")
    
    # Load RTL output
    try:
        rtl_output = []
        with open('output.txt', 'r') as f:
            for line in f:
                parts = line.strip().split()
                if len(parts) == 2:
                    # Parse as hexadecimal
                    re_val = int(parts[0], 16)
                    im_val = int(parts[1], 16)
                    rtl_output.append((re_val, im_val))
        print(f"\nLoaded {len(rtl_output)} samples from RTL output")
    except:
        print("Error: Could not load output.txt")
        print("Please run the Verilog simulation first")
        return
    
    # Compare outputs
    print("\n" + "=" * 70)
    print("Verification Results")
    print("=" * 70)
    
    expected_samples = num_golden_frames * N_FFT
    actual_samples = len(rtl_output)
    
    print(f"Expected samples: {expected_samples} ({num_golden_frames} frames × {N_FFT})")
    print(f"Actual samples:   {actual_samples}")
    
    if actual_samples != expected_samples:
        print(f"\n⚠ WARNING: Sample count mismatch!")
    
    # Compare sample by sample
    errors = []
    max_samples = min(expected_samples, actual_samples)
    
    for i in range(max_samples):
        frame_idx = i // N_FFT
        sample_idx = i % N_FFT
        
        golden_re = float_to_q15(golden_frames_re[frame_idx][sample_idx])
        golden_im = float_to_q15(golden_frames_im[frame_idx][sample_idx])
        
        # Convert golden to unsigned 16-bit representation for comparison
        golden_re_u16 = golden_re & 0xFFFF
        golden_im_u16 = golden_im & 0xFFFF
        
        rtl_re = rtl_output[i][0]
        rtl_im = rtl_output[i][1]
       
        # Calculate error (both are now unsigned 16-bit)
        err_re = abs(golden_re_u16 - rtl_re)
        err_im = abs(golden_im_u16 - rtl_im)

        if err_re > 0 or err_im > 0:
            errors.append({
                'index': i,
                'frame': frame_idx,
                'sample': sample_idx,
                'golden_re': golden_re,
                'golden_im': golden_im,
                'golden_re_u16': golden_re_u16,
                'golden_im_u16': golden_im_u16,
                'rtl_re': rtl_re,
                'rtl_im': rtl_im,
                'err_re': err_re,
                'err_im': err_im
            })
    
    # Print results
    if len(errors) == 0:
        print("\n✓ PASS: All samples match perfectly!")
    else:
        print(f"\n✗ FAIL: Found {len(errors)} mismatches")
        print(f"Error rate: {len(errors)/max_samples*100:.2f}%")
        
        # Show first few errors
        print("\nFirst 10 errors:")
        for err in errors[:10]:
            print(f"  Sample {err['index']} (Frame {err['frame']}, Pos {err['sample']}):")
            print(f"    Golden: RE={err['golden_re']:6d} (0x{err['golden_re_u16']:04x}), IM={err['golden_im']:6d} (0x{err['golden_im_u16']:04x})")
            print(f"    RTL:    RE={err['rtl_re']:6d} (0x{err['rtl_re']:04x}), IM={err['rtl_im']:6d} (0x{err['rtl_im']:04x})")
            print(f"    Error:  RE={err['err_re']:6d}, IM={err['err_im']:6d}")
    
    # Generate comparison plots
    if actual_samples > 0:
        plot_comparison(rtl_output, golden_frames_re, golden_frames_im, num_golden_frames)
    
    print("\n" + "=" * 70)

def plot_comparison(rtl_output, golden_re, golden_im, num_frames):
    """Plot RTL output vs Golden reference"""
    
    # Convert golden to 1D arrays
    golden_re_1d = np.concatenate([frame for frame in golden_re])
    golden_im_1d = np.concatenate([frame for frame in golden_im])
    golden_re_q15 = np.array([float_to_q15(x) for x in golden_re_1d])
    golden_im_q15 = np.array([float_to_q15(x) for x in golden_im_1d])
    
    # Convert RTL output
    rtl_re = np.array([x[0] for x in rtl_output])
    rtl_im = np.array([x[1] for x in rtl_output])
    
    # Truncate to same length
    min_len = min(len(golden_re_q15), len(rtl_re))
    
    fig, axes = plt.subplots(4, 1, figsize=(14, 10))
    
    # Plot 1: Real part comparison
    axes[0].plot(golden_re_q15[:min_len], 'b-', label='Golden', linewidth=1, alpha=0.7)
    axes[0].plot(rtl_re[:min_len], 'r--', label='RTL', linewidth=1, alpha=0.7)
    axes[0].set_title('Real Part Comparison')
    axes[0].set_ylabel('Value (Q15)')
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)
    
    # Plot 2: Imaginary part comparison
    axes[1].plot(golden_im_q15[:min_len], 'b-', label='Golden', linewidth=1, alpha=0.7)
    axes[1].plot(rtl_im[:min_len], 'r--', label='RTL', linewidth=1, alpha=0.7)
    axes[1].set_title('Imaginary Part Comparison')
    axes[1].set_ylabel('Value (Q15)')
    axes[1].legend()
    axes[1].grid(True, alpha=0.3)
    
    # Plot 3: Error in real part
    err_re = rtl_re[:min_len] - golden_re_q15[:min_len]
    axes[2].stem(err_re, linefmt='b-', basefmt=' ')
    axes[2].set_title('Error in Real Part (RTL - Golden)')
    axes[2].set_ylabel('Error')
    axes[2].grid(True, alpha=0.3)
    
    # Plot 4: Error in imaginary part
    err_im = rtl_im[:min_len] - golden_im_q15[:min_len]
    axes[3].stem(err_im, linefmt='r-', basefmt=' ')
    axes[3].set_title('Error in Imaginary Part (RTL - Golden)')
    axes[3].set_xlabel('Sample Index')
    axes[3].set_ylabel('Error')
    axes[3].grid(True, alpha=0.3)
    
    # Add frame boundaries
    for ax in axes:
        for i in range(num_frames):
            frame_start = i * N_FFT
            ax.axvline(x=frame_start, color='g', linestyle='--', alpha=0.3, linewidth=1)
    
    plt.tight_layout()
    plt.savefig('verification_plot.png', dpi=150)
    print(f"Verification plot saved to: verification_plot.png")
    plt.show()

if __name__ == "__main__":
    main()
