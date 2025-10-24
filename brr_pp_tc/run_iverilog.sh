#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Generate test data
echo "--- Generating test data ---"
python3 verify.py generate

# Compile the Verilog files
echo "--- Compiling Verilog files ---"
iverilog -o tb_brr_pp.vvp ../BitRevReorder.v tb_BRR_PP.v

# Run the simulation
echo "--- Running simulation ---"
vvp tb_brr_pp.vvp

# # Verify the output
# echo "--- Verifying output ---"
# python3 verify.py verify
