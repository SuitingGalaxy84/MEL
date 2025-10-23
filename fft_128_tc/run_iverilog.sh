#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Generate test data
echo "--- Generating test data ---"
python3 verify_fft.py generate

# Compile the Verilog files
echo "--- Compiling Verilog files ---"
iverilog -o tb128.vvp -g2005-sv \
    ../FFT128.v \
    ../SdfUnit_TC.v \
    ../SdfUnit2.v \
    ../Butterfly.v \
    ../DelayBuffer.v \
    ../Multiply.v \
    ../TwiddleConvert8.v \
    ../Twiddle128.v \
    TB128.v

# Run the simulation
echo "--- Running simulation ---"
vvp tb128.vvp

# Verify the output
echo "--- Verifying output ---"
python3 verify_fft.py verify
