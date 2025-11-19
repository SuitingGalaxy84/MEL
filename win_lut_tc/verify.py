import os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
# Parameters
WIDTH = 16
N_FFT = 512
WIN_LEN = 480
HOP_LEN = 160
Q_FORMAT = 15
VIVADO = True  # Set to True if RTL output is from Vivado simulator

def u16_to_signed(val):
    """Convert unsigned 16-bit value to signed integer."""
    return val - 0x10000 if val & 0x8000 else val

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
    """Generate a Hann window matching the RTL LUT."""
    n = np.arange(WIN_LEN)
    window = 0.5 - 0.5 * np.cos((2 * np.pi * n) / (WIN_LEN - 1))
    return window

def apply_window_golden(input_re, input_im, window):
    """
    Apply windowing operation - Golden reference model
    
    The Window_lut module:
    1. Accumulates WIN_LEN samples in a circular buffer
    2. Every N_FFT cycles, outputs a windowed frame:
       - First WIN_LEN samples are multiplied by window coefficients
       - The result is centered in an N_FFT-length output frame (zero-padded)
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
        
        # Zero-pad to N_FFT length: symmetrical padding
        padded_re = np.zeros(N_FFT)
        padded_im = np.zeros(N_FFT)
        padded_re[(N_FFT - WIN_LEN) // 2: WIN_LEN + (N_FFT - WIN_LEN) // 2] = windowed_re
        padded_im[(N_FFT - WIN_LEN) // 2: WIN_LEN + (N_FFT - WIN_LEN) // 2] = windowed_im

        output_frames_re.append(padded_re)
        output_frames_im.append(padded_im)
    
    return output_frames_re, output_frames_im

def summarize_error_stats(error_values):
    if len(error_values) == 0:
        return 0.0, 0.0, 0.0
    error_array = np.array(error_values, dtype=np.float64)
    max_abs = np.max(np.abs(error_array))
    mean_abs = np.mean(np.abs(error_array))
    rms = np.sqrt(np.mean(error_array ** 2))
    return max_abs, mean_abs, rms

def analyze_frame_log(expected_frames):
    path = 'frame_log_vivado.txt' if VIVADO else 'frame_log.txt'
    if not os.path.exists(path):
        print(f"\n{path} not found - skipping buffer control diagnostics.")
        return

    # We will reconstruct the testbench's sample_count by counting cycles
    # where 'dien' (den) is asserted. Then detect rising edges of 'doen'
    # (dout_en) to mark frame starts and measure hop lengths.
    sample_count = 0
    prev_doen = '0'
    prev_frm_init = '0'
    prev_jump = '0'
    prev_ir_ptr = '0'
    frame_starts = []
    frame_lengths = []
    frame_jumps = []
    in_frame = False

    with open(path, 'r') as fh:
        header = fh.readline()
        if not header:
            print("\nframe_log.txt is empty - no frame events captured.")
            return

        # Map header fields to indices for robust parsing
        cols = [c.strip() for c in header.strip().split()]
        # Expected names include: rst_n, dien, doen, ptr, cnt, full, empty, w_ptr, r_ptr, iw_ptr, ir_ptr, jump, init, re, im
        try:
            idx_dien = cols.index('dien')
            idx_doen = cols.index('doen')
            idx_frm_init = cols.index('init')
            idx_ir_ptr = cols.index('ir_ptr')
            idx_jump = cols.index('jump')
        except ValueError:
            # Fallback: try common alternatives
            idx_dien = 1
            idx_doen = 2
            idx_frm_init = 12
            idx_ir_ptr = 10
            idx_jump = 11

        for line in fh:
            if line.strip() == '':
                continue
            parts = line.strip().split()

            # Safely read dien/doen values (may be 'x' during reset)
            dien = parts[idx_dien] if idx_dien < len(parts) else '0'
            doen = parts[idx_doen] if idx_doen < len(parts) else '0'
            frm_init = parts[idx_frm_init] if idx_frm_init < len(parts) else '0'
            ir_ptr = parts[idx_ir_ptr] if idx_ir_ptr < len(parts) else '0'
            jump = parts[idx_jump] if idx_jump < len(parts) else '0'
            # Update sample_count like the TB: increment when den (dien) is '1'
            

            if frm_init == '1' and in_frame:
                # Frame ended on this cycle
                print(f"Frame end at sample {sample_count}")
                frame_len = sample_count - frame_starts[-1] + 1
                frame_lengths.append(frame_len)
                in_frame = False

            if prev_doen != '1' and doen == '1' or (frm_init == "0" and prev_frm_init == "1" and doen != "0"):
                # Frame start observed at current sample_count
                print(f"Frame start at sample {sample_count}")
                frame_starts.append(sample_count)
                in_frame = True

            if doen == "1":
                sample_count += 1

            if prev_jump == "1" and jump == "0":
                frame_jumps.append(int(ir_ptr))

            prev_doen = doen
            prev_frm_init = frm_init
            prev_jump = jump    
            prev_ir_ptr = ir_ptr

    # In case the file ends while still in a frame
    # if in_frame and current_frame_len > 0:
        # frame_lengths.append(current_frame_len)

    print("\n" + "=" * 70)
    print("Buffer Control Check")
    print("=" * 70)
    print(f"Observed frames: {len(frame_starts)}")

    if len(frame_lengths) > 0:
        for i in range(len(frame_lengths)):
            frame_length = frame_lengths[i]
            status = "PASS" if frame_length == N_FFT else "FAIL"
            print(f"Frame {i+1}: Δsamples = {frame_length} (expected {N_FFT}) -> {status}")    

    else:
        print("Not enough frames to evaluate hop behavior.")

    # Frame length check: DUT prints N_FFT samples (TB uses N_FFT-1 in check because of counter semantics)
    if len(frame_lengths) >= 2:
        hop_lengths = []
        for i in range(1, len(frame_jumps)):
            hop = frame_jumps[i] - frame_jumps[i-1]
            hop_lengths.append(hop)
            status = "PASS" if hop == HOP_LEN else "FAIL"
            print(f"Hop {i}: Δsamples = {hop} (expected {HOP_LEN}) -> {status}")

    if expected_frames is not None and expected_frames != len(frame_starts):
        print(f"⚠ Frame count mismatch: expected {expected_frames}, observed {len(frame_starts)}")

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
        output_file = 'output_vivado.txt' if VIVADO else 'output.txt'
        with open(output_file, 'r') as f:
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
    error_values_re = []
    error_values_im = []
    max_samples = min(expected_samples, actual_samples)
    
    for i in range(max_samples):
        frame_idx = i // N_FFT
        sample_idx = i % N_FFT
        
        golden_re = golden_frames_re[frame_idx][sample_idx]
        golden_im = golden_frames_im[frame_idx][sample_idx]
        
    
        rtl_re_u16 = rtl_output[i][0]
        rtl_im_u16 = rtl_output[i][1]
        rtl_re_signed = u16_to_signed(rtl_re_u16)
        rtl_im_signed = u16_to_signed(rtl_im_u16)
        rtl_re_signed_float = q15_to_float(rtl_re_signed)
        rtl_im_signed_float = q15_to_float(rtl_im_signed)


        err_re_signed = rtl_re_signed_float - golden_re
        err_im_signed = rtl_im_signed_float - golden_im

        error_values_re.append(err_re_signed)
        error_values_im.append(err_im_signed)

        if golden_re != rtl_re_signed_float or golden_im != rtl_im_signed_float:
            errors.append({
                'index': i,
                'frame': frame_idx,
                'sample': sample_idx,
                'golden_re': golden_re,
                'golden_im': golden_im,
                'rtl_re': rtl_re_signed_float,
                'rtl_im': rtl_im_signed_float,
                'err_re': err_re_signed,
                'err_im': err_im_signed
            })
    
    # Print results
    if len(errors) == 0:
        print("\n✓ PASS: All samples match perfectly!")
    else:
        print(f"\n✗ FAIL: Found {len(errors)} mismatches")
        print(f"Error rate: {len(errors)/max_samples*100:.2f}%")
        
        # Show first few errors
        # print("\nFirst 10 errors:")
        # for err in errors[:10]:
        #     print(f"  Sample {err['index']} (Frame {err['frame']}, Pos {err['sample']}):")
        #     print(f"    Golden: RE={err['golden_re']:6f}, IM={err['golden_im']:6f}")
        #     print(f"    RTL:    RE={err['rtl_re']:6f}, IM={err['rtl_im']:6f}")
        #     print(f"    Error:  RE={err['err_re']:6f}, IM={err['err_im']:6f}")

    max_abs_re, mean_abs_re, rms_re = summarize_error_stats(error_values_re)
    max_abs_im, mean_abs_im, rms_im = summarize_error_stats(error_values_im)

    print("\nError Metrics (Q15 LSB):")
    print(f"  Real: max={max_abs_re:.0f}, mean={mean_abs_re:.4f}, rms={rms_re:.4f}")
    print(f"        max_float={max_abs_re / (2**Q_FORMAT):.6e}")
    print(f"  Imag: max={max_abs_im:.0f}, mean={mean_abs_im:.4f}, rms={rms_im:.4f}")
    print(f"        max_float={max_abs_im / (2**Q_FORMAT):.6e}")
    
    # Generate comparison plots
    if actual_samples > 0:
        rtl_re_float = np.array([q15_to_float(u16_to_signed(sample[0])) for sample in rtl_output])
        rtl_im_float = np.array([q15_to_float(u16_to_signed(sample[1])) for sample in rtl_output])
        plot_comparison(rtl_re_float, rtl_im_float, golden_frames_re, golden_frames_im, num_golden_frames)
        plot_frame_by_frame(rtl_re_float, rtl_im_float, golden_frames_re, golden_frames_im, num_golden_frames)
    
    analyze_frame_log(num_golden_frames)
    print("\n" + "=" * 70)

def plot_comparison(rtl_re, rtl_im, golden_re, golden_im, num_frames):
    """Plot combined RTL output vs Golden reference"""

    if len(rtl_re) == 0:
        print("No RTL samples to plot.")
        return

    # Convert golden to 1D arrays
    golden_re_1d = np.concatenate([frame for frame in golden_re])
    golden_im_1d = np.concatenate([frame for frame in golden_im])

    # Truncate to same length
    min_len = min(len(golden_re_1d), len(rtl_re))

    fig, axes = plt.subplots(4, 1, figsize=(14, 10))

    # Plot 1: Real part comparison
    axes[0].plot(golden_re_1d[:min_len], 'b-', label='Golden', linewidth=1, alpha=0.7)
    axes[0].plot(rtl_re[:min_len], 'r--', label='RTL', linewidth=1, alpha=0.7)
    axes[0].set_title('Real Part Comparison')
    axes[0].set_ylabel('Value (float)')
    axes[0].legend()
    axes[0].grid(True, alpha=0.3)

    # Plot 2: Imaginary part comparison
    axes[1].plot(golden_im_1d[:min_len], 'b-', label='Golden', linewidth=1, alpha=0.7)
    axes[1].plot(rtl_im[:min_len], 'r--', label='RTL', linewidth=1, alpha=0.7)
    axes[1].set_title('Imaginary Part Comparison')
    axes[1].set_ylabel('Value (float)')
    axes[1].legend()
    axes[1].grid(True, alpha=0.3)

    # Plot 3: Error in real part
    err_re = rtl_re[:min_len] - golden_re_1d[:min_len]
    axes[2].stem(err_re, linefmt='b-', basefmt=' ')
    axes[2].set_title('Error in Real Part (RTL - Golden)')
    axes[2].set_ylabel('Error')
    axes[2].grid(True, alpha=0.3)

    # Plot 4: Error in imaginary part
    err_im = rtl_im[:min_len] - golden_im_1d[:min_len]
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
    plt.close(fig)
    print("Verification plot saved to: verification_plot.png")


def plot_frame_by_frame(rtl_re, rtl_im, golden_re_frames, golden_im_frames, num_frames):
    """Create per-frame signal/error plots (vf/vf_fX.png)."""

    if num_frames == 0:
        print("No golden frames available for frame-by-frame plotting.")
        return
    vf_dir = 'vf_vivado' if VIVADO else 'vf'
    os.makedirs(vf_dir, exist_ok=True)

    total_samples = min(len(rtl_re), len(rtl_im), num_frames * N_FFT)
    if total_samples == 0:
        print("No RTL samples available for frame-by-frame plotting.")
        return

    max_frames = min(num_frames, len(golden_re_frames), len(golden_im_frames), total_samples // N_FFT)
    if max_frames == 0:
        print("Insufficient samples to generate per-frame plots.")
        return

    for frame_idx in range(max_frames):
        start = frame_idx * N_FFT
        end = start + N_FFT
        rtl_frame_re = rtl_re[start:end]
        rtl_frame_im = rtl_im[start:end]
        golden_frame_re = golden_re_frames[frame_idx][:N_FFT]
        golden_frame_im = golden_im_frames[frame_idx][:N_FFT]

        err_re = rtl_frame_re - golden_frame_re
        err_im = rtl_frame_im - golden_frame_im

        fig, axes = plt.subplots(4, 1, figsize=(14, 10), sharex=True)
        fig.suptitle(f'Frame {frame_idx + 1}')

        axes[0].plot(golden_frame_re, 'b-', label='Golden', linewidth=1, alpha=0.8)
        axes[0].plot(rtl_frame_re, 'r--', label='RTL', linewidth=1, alpha=0.8)
        axes[0].set_ylabel('Real')
        axes[0].set_title('Real Part (Signal)')
        axes[0].legend()
        axes[0].grid(True, alpha=0.3)

        axes[1].plot(golden_frame_im, 'b-', label='Golden', linewidth=1, alpha=0.8)
        axes[1].plot(rtl_frame_im, 'r--', label='RTL', linewidth=1, alpha=0.8)
        axes[1].set_ylabel('Imag')
        axes[1].set_title('Imaginary Part (Signal)')
        axes[1].grid(True, alpha=0.3)

        axes[2].stem(err_re, linefmt='b-', basefmt=' ')
        axes[2].set_ylabel('Error (Real)')
        axes[2].set_title('Real Part Error (RTL - Golden)')
        axes[2].grid(True, alpha=0.3)

        axes[3].stem(err_im, linefmt='r-', basefmt=' ')
        axes[3].set_ylabel('Error (Imag)')
        axes[3].set_xlabel('Sample Index')
        axes[3].set_title('Imaginary Part Error (RTL - Golden)')
        axes[3].grid(True, alpha=0.3)

        fig.tight_layout(rect=(0, 0, 1, 0.97))
        plot_path = os.path.join(vf_dir, f'vf_f{frame_idx + 1}.png')
        fig.savefig(plot_path, dpi=150)
        plt.close(fig)
        print(f"Saved frame plot: {plot_path}")
    

if __name__ == "__main__":
    main()
