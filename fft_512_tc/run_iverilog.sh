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

if [ -f "output1.txt" ]; then
    size1=$(stat -f%z "output1.txt" 2>/dev/null || stat -c%s "output1.txt" 2>/dev/null)
    echo "  [OK] output1.txt generated ($size1 bytes)"
else
    echo "  [FAIL] output1.txt not found!"
    success=false
fi

if [ -f "output2.txt" ]; then
    size2=$(stat -f%z "output2.txt" 2>/dev/null || stat -c%s "output2.txt" 2>/dev/null)
    echo "  [OK] output2.txt generated ($size2 bytes)"
else
    echo "  [FAIL] output2.txt not found!"
    success=false
fi
echo ""

# Final status
echo "===================================="
if [ "$success" = true ]; then
    echo "SIMULATION COMPLETED SUCCESSFULLY!"
else
    echo "SIMULATION COMPLETED WITH ERRORS!"
fi
echo "===================================="

echo "--- Verifying bit-reversal of FFT output ---"
python3 verify_fft.py verify
