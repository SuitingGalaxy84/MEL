#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

rm tb_brr_pp.vvp || true

# Generate test data
echo "--- Generating test data ---"
python3 verify.py generate

# Compile the Verilog files
echo "--- Compiling Verilog files ---"
iverilog -o tb_brr_pp.vvp ../pp_buffer.v tb_pp_buffer.v ../buffer.v

# Run the simulation
echo "--- Running simulation ---"
vvp tb_brr_pp.vvp

# # Verify the output
# echo "--- Verifying output ---"
# python3 verify.py verify
