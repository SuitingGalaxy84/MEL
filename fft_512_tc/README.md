# FFT512 Test Case

This directory contains test files for the 512-point FFT implementation.

## Contents

- `TB512.v` - Verilog testbench for FFT512
- `stim.v` - Test stimulus file
- `run_iverilog.ps1` - PowerShell script to run the simulation (Windows)
- `run_iverilog.sh` - Bash script to run the simulation (Linux/WSL)
- `verify_fft.py` - Python script for verification and test vector generation
- `generate_data.py` - Standalone script for generating various test vectors

## FFT512 Configuration

- **FFT Size**: 512 points
- **Architecture**: Radix-2^2 Single-Path Delay Feedback (SDF)
- **Data Format**: Q1.15 fixed-point (16-bit)
- **Scaling**: 1/N (1/512)
- **Output Order**: Bit-reversed (testbench converts back to natural order in output files)

## Running the Testbench

### Windows (PowerShell)
```powershell
cd fft_512_tc
.\run_iverilog.ps1
```

### Linux/WSL (Bash)
```bash
cd fft_512_tc
chmod +x run_iverilog.sh
./run_iverilog.sh
```

## Test Vectors

### Standard Test Vectors

The `generate_data.py` script can generate multiple test vectors:

1. **Test Vector 1** (`input1.txt`): DC Impulse
   - Single impulse at sample 0
   - Tests FFT's ability to handle DC component
   - Expected output: Equal magnitude across all bins

2. **Test Vector 2** (`input2.txt`): Single frequency sine wave
   - Sine wave at frequency bin 10
   - Tests FFT's frequency resolution
   - Expected output: Peak at bin 10

3. **Test Vector 3** (`input3.txt`): Complex exponential
   - Complex tone at bin 20
   - Tests complex signal processing
   - Expected output: Single peak at bin 20

4. **Test Vector 4** (`input4.txt`): Multi-tone signal
   - Sum of sine waves at bins 5, 15, 25, 50
   - Tests multiple frequency detection
   - Expected output: Peaks at specified bins

5. **Test Vector 5** (`input5.txt`): White noise
   - Random white noise
   - Tests FFT with broadband signal
   - Expected output: Flat spectrum

6. **Test Vector 6** (`input6.txt`): Nyquist frequency
   - Sine wave at bin 256 (N/2)
   - Tests maximum frequency handling
   - Expected output: Peak at Nyquist frequency

7. **Test Vector 7** (`input7.txt`): Chirp signal
   - Linear frequency sweep from 0 to 100 bins
   - Tests FFT with varying frequencies
   - Expected output: Distributed energy across bins

8. **Test Vector 8** (`input8.txt`): Cosine wave
   - Cosine wave at frequency bin 30
   - Tests phase-shifted sinusoid
   - Expected output: Peak at bin 30

### Generating Custom Test Vectors

Use `generate_data.py` for custom test vectors:

```bash
# Generate all standard vectors
python generate_data.py

# Generate custom sine wave at bin 25
python generate_data.py --type sine --bin 25 --amp 0.9 --output my_sine.txt

# Generate impulse at position 50
python generate_data.py --type impulse --pos 50 --output my_impulse.txt

# Generate multi-tone with specific bins
python generate_data.py --type multi --bins 12 24 48 96 --output my_multi.txt

# Generate chirp signal
python generate_data.py --type chirp --amp 0.7 --output my_chirp.txt

# Generate noise with specific seed
python generate_data.py --type noise --amp 0.4 --seed 123 --output my_noise.txt
```

### Available Vector Types

- `impulse` - Delta function at specified position
- `sine` - Sine wave at specified frequency bin
- `cosine` - Cosine wave at specified frequency bin
- `complex` - Complex exponential
- `multi` - Sum of multiple frequencies
- `chirp` - Linear frequency sweep
- `noise` - White noise
- `square` - Square wave
- `sawtooth` - Sawtooth wave
- `all` - Generate all standard vectors (default)

## Verification

The verification script:
- Generates test input vectors
- Computes golden reference using NumPy FFT
- Compares RTL output with golden reference
- Generates visualization plots
- Reports maximum error and pass/fail status

### Manual Verification Steps

1. **Generate test vectors**:
   ```bash
   # Generate all standard test vectors
   python generate_data.py
   
   # Or use verify script's generate mode
   python verify_fft.py generate
   ```

2. **Run simulation** (creates `output1.txt`, `output2.txt`, etc.)

3. **Verify results**:
   ```bash
   python verify_fft.py verify
   ```

## File Format

Input and output files use hexadecimal format:
```
<real_hex>  <imag_hex>  // <index>
```

Example:
```
7fff  0000  // 0
0000  0000  // 1
...
```

## Dependencies

- **Iverilog**: Verilog simulator
- **Python 3**: For verification scripts
- **NumPy**: For FFT computation
- **Matplotlib**: For visualization (optional)

## Expected Results

The FFT implementation should match the NumPy golden reference within ±2 Q1.15 units (tolerance for fixed-point quantization errors).

## Notes

- The testbench timeout is set to 5000 clock cycles to accommodate the larger FFT size
- Output files are in natural order (testbench performs bit-reversal when saving)
- The Q1.15 format represents values in the range [-1.0, 0.99997...]
