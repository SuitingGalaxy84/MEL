import numpy as np
import matplotlib.pyplot as plt

# Parameters
WIDTH = 16
N_FFT = 512
WIN_LEN = 480
HOP_LEN = 160
Q_FORMAT = 15  # Q0.15 fixed-point format

# Number of samples to generate
# We need at least WIN_LEN samples for the first frame,
# then HOP_LEN more samples for each additional frame
NUM_FRAMES = 3
NUM_SAMPLES = WIN_LEN + (NUM_FRAMES - 1) * HOP_LEN

def float_to_q15(val):
    """Convert floating point to Q0.15 fixed-point format"""
    # Q0.15: 1 sign bit, 15 fractional bits
    # Range: -1.0 to +0.999969482421875
    max_val = 2**15 - 1  # 32767
    min_val = -2**15     # -32768
    
    fixed = int(round(val * (2**Q_FORMAT)))
    fixed = max(min_val, min(max_val, fixed))  # Clamp to valid range
    
    # Convert to signed 16-bit
    if fixed < 0:
        fixed = (1 << 16) + fixed
    
    return fixed & 0xFFFF

def q15_to_float(val):
    """Convert Q0.15 fixed-point to floating point"""
    # Handle sign extension
    if val & 0x8000:
        val = val - 0x10000
    return val / (2**Q_FORMAT)

def generate_test_signal(num_samples, signal_type='multi_tone', cplx = False):
    """
    Generate test signals for window function testing
    
    signal_type options:
    - 'multi_tone': Multiple sinusoids
    - 'chirp': Frequency sweep
    - 'impulse': Impulse response
    - 'random': Random signal
    """
    t = np.arange(num_samples)
    
    if signal_type == 'multi_tone':
        # Multiple frequency components
        # Normalized frequencies (fraction of sampling rate)
        f1 = 0.05  # Low frequency
        f2 = 0.15  # Mid frequency  
        f3 = 0.25  # Higher frequency
        
        signal_re = (0.3 * np.cos(2 * np.pi * f1 * t) +
                    0.4 * np.cos(2 * np.pi * f2 * t) +
                    0.2 * np.cos(2 * np.pi * f3 * t))
        
        signal_im = (0.3 * np.sin(2 * np.pi * f1 * t) +
                    0.4 * np.sin(2 * np.pi * f2 * t) +
                    0.2 * np.sin(2 * np.pi * f3 * t))
        
        # Normalize to prevent overflow
        max_amp = max(np.max(np.abs(signal_re)), np.max(np.abs(signal_im)))
        if max_amp > 0.9:
            signal_re = signal_re * 0.9 / max_amp
            signal_im = signal_im * 0.9 / max_amp
            
    elif signal_type == 'chirp':
        # Linear frequency sweep
        f_start = 0.01
        f_end = 0.4
        phase = 2 * np.pi * (f_start * t + (f_end - f_start) * t**2 / (2 * num_samples))
        signal_re = 0.7 * np.cos(phase)
        signal_im = 0.7 * np.sin(phase)
        
    elif signal_type == 'impulse':
        # Impulse at different positions for each frame
        signal_re = np.zeros(num_samples)
        signal_im = np.zeros(num_samples)
        # Place impulses
        impulse_positions = [50, 210, 370, 530]
        for pos in impulse_positions:
            if pos < num_samples:
                signal_re[pos] = 0.8
                signal_im[pos] = 0.8
                
    elif signal_type == 'random':
        # Random signal (good for general testing)
        signal_re = 0.5 * np.random.randn(num_samples)
        signal_im = 0.5 * np.random.randn(num_samples)
        
    else:
        raise ValueError(f"Unknown signal type: {signal_type}")
    
    if not cplx:
        signal_im = np.zeros(num_samples)

    return signal_re, signal_im

def main():
    print("=" * 60)
    print("Window LUT Testbench - Input Data Generator")
    print("=" * 60)
    print(f"Parameters:")
    print(f"  WIDTH     = {WIDTH}")
    print(f"  N_FFT     = {N_FFT}")
    print(f"  WIN_LEN   = {WIN_LEN}")
    print(f"  HOP_LEN   = {HOP_LEN}")
    print(f"  NUM_FRAMES = {NUM_FRAMES}")
    print(f"  NUM_SAMPLES = {NUM_SAMPLES}")
    print("=" * 60)
    
    # Generate test signal
    signal_type = 'multi_tone'  # Change this to test different signals
    signal_re, signal_im = generate_test_signal(NUM_SAMPLES, signal_type)
    
    # Convert to Q15 format
    input_data_re = []
    input_data_im = []
    
    for i in range(NUM_SAMPLES):
        re_q15 = float_to_q15(signal_re[i])
        im_q15 = float_to_q15(signal_im[i])
        input_data_re.append(re_q15)
        input_data_im.append(im_q15)
    
    # Write input file for Verilog testbench
    with open('input.txt', 'w') as f:
        for i in range(NUM_SAMPLES):
            # Write as hexadecimal (16-bit unsigned representation)
            f.write(f"{input_data_re[i]:04x} {input_data_im[i]:04x}\n")
    
    print(f"\nGenerated {NUM_SAMPLES} samples using '{signal_type}' signal")
    print(f"Input data written to: input.txt")
    
    # Also save floating-point version for verification
    np.savez('input_float.npz', 
             signal_re=signal_re, 
             signal_im=signal_im,
             params={'WIDTH': WIDTH, 'N_FFT': N_FFT, 'WIN_LEN': WIN_LEN, 'HOP_LEN': HOP_LEN})
    print(f"Floating-point reference saved to: input_float.npz")
    
    # Plot the input signal
    fig, axes = plt.subplots(3, 1, figsize=(12, 8))
    
    # Real part
    axes[0].plot(signal_re, 'b-', linewidth=0.8)
    axes[0].set_title('Input Signal - Real Part')
    axes[0].set_xlabel('Sample')
    axes[0].set_ylabel('Amplitude')
    axes[0].grid(True, alpha=0.3)
    axes[0].axhline(y=0, color='k', linestyle='-', linewidth=0.5)
    
    # Imaginary part
    axes[1].plot(signal_im, 'r-', linewidth=0.8)
    axes[1].set_title('Input Signal - Imaginary Part')
    axes[1].set_xlabel('Sample')
    axes[1].set_ylabel('Amplitude')
    axes[1].grid(True, alpha=0.3)
    axes[1].axhline(y=0, color='k', linestyle='-', linewidth=0.5)
    
    # Magnitude
    magnitude = np.sqrt(signal_re**2 + signal_im**2)
    axes[2].plot(magnitude, 'g-', linewidth=0.8)
    axes[2].set_title('Input Signal - Magnitude')
    axes[2].set_xlabel('Sample')
    axes[2].set_ylabel('Amplitude')
    axes[2].grid(True, alpha=0.3)
    
    # Mark frame boundaries
    for ax in axes:
        for i in range(NUM_FRAMES):
            frame_start = i * HOP_LEN
            ax.axvline(x=frame_start, color='m', linestyle='--', alpha=0.5, linewidth=1)
            ax.text(frame_start, ax.get_ylim()[1]*0.9, f'Frame {i+1}', 
                   rotation=90, verticalalignment='top', fontsize=8)
    
    plt.tight_layout()
    plt.savefig('input_signal.png', dpi=150)
    print(f"Input signal plot saved to: input_signal.png")
    
    plt.show()
    
    print("\n" + "=" * 60)
    print("Data generation complete!")
    print("=" * 60)

if __name__ == "__main__":
    main()
