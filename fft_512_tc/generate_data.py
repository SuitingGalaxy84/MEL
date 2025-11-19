"""
FFT512 Test Data Generator
---------------------------
Generates various test input vectors for FFT512 verification.
Produces hexadecimal format files compatible with Verilog $readmemh.

Supported test vectors:
1. DC Impulse - Single impulse at sample 0
2. Sine wave - Single frequency at specified bin
3. Complex tone - Sine wave with real and imaginary components
4. Multi-tone - Sum of multiple frequencies
5. Chirp - Frequency sweep
6. Random noise - White noise
"""

import numpy as np
import argparse
import sys

def float_to_q15(val):
    """Convert float to Q1.15 fixed-point"""
    # Clamp to valid range
    val = np.clip(val, -1.0, 0.99997)
    return int(np.round(val * 32768.0))

def q15_to_float(val):
    """Convert Q1.15 fixed-point to float"""
    return val / 32768.0

def signed_to_hex(val):
    """Convert signed 16-bit value to hex string"""
    if val < 0:
        val = val + 0x10000
    return f"{val:04x}"

def save_test_vector(filename, data_re, data_im, description=""):
    """Save test vector to hex file"""
    N = len(data_re)
    with open(filename, 'w') as f:
        if description:
            f.write(f"// {description}\n")
        for i in range(N):
            f.write(f"{signed_to_hex(data_re[i])}  {signed_to_hex(data_im[i])}  // {i}\n")
    print(f"Generated: {filename} - {description}")

def generate_dc_impulse(N=512, amplitude=0.99):
    """Generate DC impulse (delta function at t=0)"""
    data_re = np.zeros(N, dtype=int)
    data_im = np.zeros(N, dtype=int)
    data_re[0] = float_to_q15(amplitude)
    return data_re, data_im

def generate_impulse(N=512, position=0, amplitude=0.99):
    """Generate impulse at specified position"""
    data_re = np.zeros(N, dtype=int)
    data_im = np.zeros(N, dtype=int)
    data_re[position] = float_to_q15(amplitude)
    return data_re, data_im

def generate_sine_wave(N=512, freq_bin=10, amplitude=0.8, phase=0.0):
    """Generate real sine wave at specified frequency bin"""
    t = np.arange(N)
    sine_wave = amplitude * np.sin(2 * np.pi * freq_bin * t / N + phase)
    data_re = np.array([float_to_q15(x) for x in sine_wave])
    data_im = np.zeros(N, dtype=int)
    return data_re, data_im

def generate_cosine_wave(N=512, freq_bin=10, amplitude=0.8, phase=0.0):
    """Generate real cosine wave at specified frequency bin"""
    t = np.arange(N)
    cosine_wave = amplitude * np.cos(2 * np.pi * freq_bin * t / N + phase)
    data_re = np.array([float_to_q15(x) for x in cosine_wave])
    data_im = np.zeros(N, dtype=int)
    return data_re, data_im

def generate_complex_tone(N=512, freq_bin=20, amplitude=0.7):
    """Generate complex exponential (e^(j*2*pi*k*n/N))"""
    t = np.arange(N)
    angle = 2 * np.pi * freq_bin * t / N
    real_part = amplitude * np.cos(angle)
    imag_part = amplitude * np.sin(angle)
    data_re = np.array([float_to_q15(x) for x in real_part])
    data_im = np.array([float_to_q15(x) for x in imag_part])
    return data_re, data_im

def generate_multi_tone(N=512, freq_bins=[10, 30, 50], amplitudes=None):
    """Generate sum of multiple sine waves"""
    if amplitudes is None:
        amplitudes = [0.3] * len(freq_bins)
    
    t = np.arange(N)
    signal = np.zeros(N)
    
    for freq_bin, amp in zip(freq_bins, amplitudes):
        signal += amp * np.sin(2 * np.pi * freq_bin * t / N)
    
    data_re = np.array([float_to_q15(x) for x in signal])
    data_im = np.zeros(N, dtype=int)
    return data_re, data_im

def generate_chirp(N=512, f_start=0, f_end=100, amplitude=0.6):
    """Generate linear frequency sweep (chirp)"""
    t = np.arange(N)
    # Linear frequency modulation
    k = (f_end - f_start) / N  # Frequency slope
    phase = 2 * np.pi * (f_start * t + 0.5 * k * t**2) / N
    chirp_signal = amplitude * np.sin(phase)
    
    data_re = np.array([float_to_q15(x) for x in chirp_signal])
    data_im = np.zeros(N, dtype=int)
    return data_re, data_im

def generate_noise(N=512, amplitude=0.3, seed=42):
    """Generate white noise"""
    np.random.seed(seed)
    noise = amplitude * np.random.randn(N)
    noise = np.clip(noise, -1.0, 0.99997)
    
    data_re = np.array([float_to_q15(x) for x in noise])
    data_im = np.zeros(N, dtype=int)
    return data_re, data_im

def generate_complex_noise(N=512, amplitude=0.3, seed=42):
    """Generate complex white noise"""
    np.random.seed(seed)
    noise_re = amplitude * np.random.randn(N)
    noise_im = amplitude * np.random.randn(N)
    noise_re = np.clip(noise_re, -1.0, 0.99997)
    noise_im = np.clip(noise_im, -1.0, 0.99997)
    
    data_re = np.array([float_to_q15(x) for x in noise_re])
    data_im = np.array([float_to_q15(x) for x in noise_im])
    return data_re, data_im

def generate_square_wave(N=512, freq_bin=8, amplitude=0.8):
    """Generate square wave at specified frequency"""
    t = np.arange(N)
    period = N / freq_bin
    square = amplitude * np.sign(np.sin(2 * np.pi * freq_bin * t / N))
    
    data_re = np.array([float_to_q15(x) for x in square])
    data_im = np.zeros(N, dtype=int)
    return data_re, data_im

def generate_sawtooth_wave(N=512, freq_bin=8, amplitude=0.7):
    """Generate sawtooth wave at specified frequency"""
    t = np.arange(N)
    period = N / freq_bin
    sawtooth = amplitude * (2 * ((t % period) / period) - 1)
    
    data_re = np.array([float_to_q15(x) for x in sawtooth])
    data_im = np.zeros(N, dtype=int)
    return data_re, data_im

def generate_all_standard_vectors():
    input_dir = "input_iverilog"
    """Generate all standard test vectors"""
    N = 512
    
    print("="*80)
    print("Generating FFT512 Standard Test Vectors")
    print("="*80)
    print(f"FFT Size: {N} points")
    print(f"Format: Q1.15 fixed-point (16-bit)")
    print("="*80)
    print()
    
    # Test 1: DC Impulse
    data_re, data_im = generate_dc_impulse(N, amplitude=0.99)
    save_test_vector(f"{input_dir}/input1.txt", data_re, data_im, 
                     "Test 1: DC Impulse (delta at n=0)")
    
    # Test 2: Sine wave at bin 10
    data_re, data_im = generate_sine_wave(N, freq_bin=10, amplitude=0.8)
    save_test_vector(f"{input_dir}/input2.txt", data_re, data_im, 
                     "Test 2: Sine wave at frequency bin 10")
    
    # Test 3: Complex tone at bin 20
    data_re, data_im = generate_complex_tone(N, freq_bin=20, amplitude=0.7)
    save_test_vector(f"{input_dir}/input3.txt", data_re, data_im, 
                     "Test 3: Complex exponential at bin 20")
    
    # Test 4: Multi-tone signal
    data_re, data_im = generate_multi_tone(N, freq_bins=[5, 15, 25, 50], 
                                           amplitudes=[0.25, 0.25, 0.25, 0.25])
    save_test_vector(f"{input_dir}/input4.txt", data_re, data_im, 
                     "Test 4: Multi-tone (bins 5, 15, 25, 50)")
    
    # Test 5: White noise
    data_re, data_im = generate_noise(N, amplitude=0.3, seed=42)
    save_test_vector(f"{input_dir}/input5.txt", data_re, data_im, 
                     "Test 5: White noise (seed=42)")
    
    # Test 6: Nyquist frequency (bin N/2)
    data_re, data_im = generate_sine_wave(N, freq_bin=N//2, amplitude=0.8)
    save_test_vector(f"{input_dir}/input6.txt", data_re, data_im, 
                     f"Test 6: Nyquist frequency (bin {N//2})")
    
    # Test 7: Chirp signal
    data_re, data_im = generate_chirp(N, f_start=0, f_end=100, amplitude=0.6)
    save_test_vector(f"{input_dir}/input7.txt", data_re, data_im, 
                     "Test 7: Linear chirp (0 to 100 bins)")
    
    # Test 8: Cosine wave at bin 30
    data_re, data_im = generate_cosine_wave(N, freq_bin=30, amplitude=0.8)
    save_test_vector(f"{input_dir}/input8.txt", data_re, data_im, 
                     "Test 8: Cosine wave at frequency bin 30")
    
    print()
    print("="*80)
    print("✓ All standard test vectors generated successfully!")
    print("="*80)

def main():
    parser = argparse.ArgumentParser(
        description='Generate test vectors for FFT512',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python generate_data.py                    # Generate all standard vectors
  python generate_data.py --type sine --bin 15 --output input_sine.txt
  python generate_data.py --type impulse --pos 10 --output input_impulse.txt
  python generate_data.py --type multi --bins 5 10 20 --output input_multi.txt
        """
    )
    
    parser.add_argument('--type', choices=['impulse', 'sine', 'cosine', 'complex', 
                                           'multi', 'chirp', 'noise', 'square', 
                                           'sawtooth', 'all'],
                       default='all', help='Type of test vector to generate')
    parser.add_argument('--size', type=int, default=512, help='FFT size (default: 512)')
    parser.add_argument('--bin', type=int, default=10, dest='freq_bin',
                       help='Frequency bin for sine/cosine/complex (default: 10)')
    parser.add_argument('--bins', type=int, nargs='+', default=[10, 30, 50],
                       help='Frequency bins for multi-tone (default: 10 30 50)')
    parser.add_argument('--pos', type=int, default=0, 
                       help='Position for impulse (default: 0)')
    parser.add_argument('--amp', type=float, default=0.8,
                       help='Amplitude (default: 0.8)')
    parser.add_argument('--output', type=str, default=None,
                       help='Output filename (default: auto-generated)')
    parser.add_argument('--seed', type=int, default=42,
                       help='Random seed for noise (default: 42)')
    
    args = parser.parse_args()
    
    if args.type == 'all':
        generate_all_standard_vectors()
        return
    
    N = args.size
    
    # Generate based on type
    if args.type == 'impulse':
        data_re, data_im = generate_impulse(N, args.pos, args.amp)
        desc = f"Impulse at position {args.pos}"
        default_file = f"input_impulse_{args.pos}.txt"
    elif args.type == 'sine':
        data_re, data_im = generate_sine_wave(N, args.freq_bin, args.amp)
        desc = f"Sine wave at bin {args.freq_bin}"
        default_file = f"input_sine_{args.freq_bin}.txt"
    elif args.type == 'cosine':
        data_re, data_im = generate_cosine_wave(N, args.freq_bin, args.amp)
        desc = f"Cosine wave at bin {args.freq_bin}"
        default_file = f"input_cosine_{args.freq_bin}.txt"
    elif args.type == 'complex':
        data_re, data_im = generate_complex_tone(N, args.freq_bin, args.amp)
        desc = f"Complex tone at bin {args.freq_bin}"
        default_file = f"input_complex_{args.freq_bin}.txt"
    elif args.type == 'multi':
        data_re, data_im = generate_multi_tone(N, args.bins)
        desc = f"Multi-tone at bins {args.bins}"
        default_file = "input_multi_tone.txt"
    elif args.type == 'chirp':
        data_re, data_im = generate_chirp(N, amplitude=args.amp)
        desc = "Linear chirp"
        default_file = "input_chirp.txt"
    elif args.type == 'noise':
        data_re, data_im = generate_noise(N, args.amp, args.seed)
        desc = f"White noise (seed={args.seed})"
        default_file = f"input_noise_{args.seed}.txt"
    elif args.type == 'square':
        data_re, data_im = generate_square_wave(N, args.freq_bin, args.amp)
        desc = f"Square wave at bin {args.freq_bin}"
        default_file = f"input_square_{args.freq_bin}.txt"
    elif args.type == 'sawtooth':
        data_re, data_im = generate_sawtooth_wave(N, args.freq_bin, args.amp)
        desc = f"Sawtooth wave at bin {args.freq_bin}"
        default_file = f"input_sawtooth_{args.freq_bin}.txt"
    else:
        print(f"Unknown type: {args.type}")
        sys.exit(1)
    
    filename = args.output if args.output else default_file
    save_test_vector(filename, data_re, data_im, desc)
    print(f"\n✓ Test vector generated: {filename}")

if __name__ == "__main__":
    main()
