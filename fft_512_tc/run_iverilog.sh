#!/bin/bash
# Bash script to compile and run FFT512 testbench using iverilog
# Author: Auto-generated
# Date: November 12, 2025

echo '--- Generating test data ---'
python3 verify_fft.py generate

echo "===================================="
echo "FFT512 Testbench - Icarus Verilog"
echo "===================================="
echo ""

# Change to the testbench directory
cd "$(dirname "$0")"

# Clean up previous simulation files
echo "[Step 1] Cleaning up previous simulation files..."
rm -f tb512.vvp output1.txt output2.txt
echo ""

# Compile the design
echo "[Step 2] Compiling Verilog files..."
iverilog -o tb512.vvp -g2005-sv \
    ../FFT512.v \
    ../SdfUnit.v \
    ../SdfUnit2.v \
    ../Butterfly.v \
    ../DelayBuffer.v \
    ../Multiply.v \
    ../Twiddle512.v \
    TB512.v

if [ $? -ne 0 ]; then
    echo "[ERROR] Compilation failed!"
    exit 1
fi

if [ -f "tb512.vvp" ]; then
    echo "  [OK] Compilation successful"
else
    echo "[ERROR] Output file tb512.vvp not found!"
    exit 1
fi
echo ""

# Run the simulation
echo "[Step 3] Running simulation..."
vvp tb512.vvp

if [ $? -ne 0 ]; then
    echo "[ERROR] Simulation failed!"
    exit 1
fi
echo ""

# Check results
echo "[Step 4] Checking results..."
success=true
INPUT_DIR="input_iverilog"
OUTPUT_DIR="output_iverilog"


for i in {1..8}; do
    input_file="${INPUT_DIR}/input${i}.txt"
    output_file="${OUTPUT_DIR}/output${i}.txt"

    if [ -f "$output_file" ]; then
        size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file" 2>/dev/null)
        echo "  [OK] $output_file generated ($size bytes)"
        echo "--- Verifying bit-reversal of FFT output ---"
        python3 verify_fft.py --input-pth "$input_file" --output-pth "$output_file"
    else
        echo "  [FAIL] $output_file not found!"
        success=false
    fi
done
echo ""

# Final status
echo "===================================="
if [ "$success" = true ]; then
    echo "SIMULATION COMPLETED SUCCESSFULLY!"
else
    echo "SIMULATION COMPLETED WITH ERRORS!"
fi
echo "===================================="


