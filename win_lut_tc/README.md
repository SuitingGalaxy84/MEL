# Window_lut Module Testbench

This directory contains the testbench for the `Window_lut` (WIN_LUT) module.

## Overview

The `Window_lut` module applies a Hann window to incoming audio samples with overlap-add processing:
- **Window Length (WIN_LEN)**: 480 samples
- **FFT Size (N_FFT)**: 512 points (with zero-padding)
- **Hop Length (HOP_LEN)**: 160 samples (overlap of 320 samples)

## Files

- `tb_Window_lut.v` - Verilog testbench
- `generate_input.py` - Python script to generate test input signals
- `verify.py` - Python script to verify RTL output against golden reference
- `run_iverilog.ps1` - PowerShell script to run the complete test flow
- `run_iverilog.sh` - Bash script to run the complete test flow (Linux/Mac)

## Generated Files

- `input.txt` - Input test data (Q15 format)
- `input_float.npz` - Floating-point reference input
- `output.txt` - RTL simulation output
- `golden_output.txt` - Expected output from golden model
- `input_signal.png` - Plot of input signal
- `verification_plot.png` - Comparison of RTL vs golden reference
- `tb_window_lut.vcd` - Waveform file for viewing in GTKWave

## Running the Test

### Windows (PowerShell)
```powershell
.\run_iverilog.ps1
```

### Linux/Mac (Bash)
```bash
chmod +x run_iverilog.sh
./run_iverilog.sh
```

### Manual Steps

1. **Generate input data:**
   ```bash
   python generate_input.py
   ```

2. **Compile and run simulation:**
   ```bash
   iverilog -g2012 -o tb_window_lut.vvp ../Sram.v ../HannWin.v ../Multiply.v ../Window_lut.v tb_Window_lut.v
   vvp tb_window_lut.vvp
   ```

3. **Verify results:**
   ```bash
   python verify.py
   ```

## Test Signal Types

The `generate_input.py` script can generate different types of test signals. Edit the script and change the `signal_type` variable:

- `'multi_tone'` - Multiple sinusoids at different frequencies (default)
- `'chirp'` - Linear frequency sweep
- `'impulse'` - Impulse response test
- `'random'` - Random signal for general testing

## Verification

The `verify.py` script:
1. Loads the input signal
2. Computes the expected windowed output (golden reference)
3. Compares RTL output with the golden reference
4. Reports any mismatches
5. Generates comparison plots

## Expected Behavior

The Window_lut module should:
1. Accept continuous input samples
2. Buffer WIN_LEN (480) samples in an SRAM
3. Every HOP_LEN (160) samples, output a windowed frame:
   - First WIN_LEN samples multiplied by Hann window coefficients
   - Remaining (N_FFT - WIN_LEN = 32) samples zero-padded
4. Assert `data_full` flag when a complete frame is ready for FFT processing
5. Implement circular buffering with overlap

## Troubleshooting

- **Missing modules:** Ensure all parent Verilog files exist in the parent directory
- **Compilation errors:** Check that you're using Icarus Verilog 10.0 or later with SystemVerilog support
- **Verification failures:** Check the waveform file (`tb_window_lut.vcd`) in GTKWave for timing issues

## Dependencies

- Icarus Verilog (iverilog)
- Python 3.x with:
  - numpy
  - matplotlib
  - scipy

Install Python dependencies:
```bash
pip install numpy matplotlib scipy
```
