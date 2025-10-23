#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Generate test data
echo "--- Generating test data ---"
python3 verify.py generate

# Compile the Verilog files
echo "--- Compiling Verilog files ---"
iverilog -o tb_bitrev.vvp ../BitRevReorder.v tb_BitRevReorder.v

# Run the simulation
echo "--- Running simulation ---"
vvp tb_bitrev.vvp

# Verify the output
echo "--- Verifying output ---"
python3 verify.py verify
