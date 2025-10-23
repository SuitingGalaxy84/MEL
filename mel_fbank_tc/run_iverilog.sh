#!/bin/bash

# Shell script to compile and run MEL_FBANK testbench using iverilog
echo "===================================="
echo "MEL_FBANK Testbench - Icarus Verilog"
echo "===================================="

cd "$(dirname "$0")"

echo "[Step 1] Generating mel filterbank coefficients..."
python3 convert/encode_mel_fb.py
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate mel filterbank coefficients!"
    exit 1
fi
echo "  [OK] Generated mel filterbank coefficients"

echo "[Step 2] Generating q15 test data..."
python3 data_gen_q15.py
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to generate q15 test data!"
    exit 1
fi
echo "  [OK] Generated q15 test data"

# Clean previous outputs
rm -f mel_output.txt
rm -f tb_Mel_fbank.vcd

echo "[Step 3] Compiling Verilog files..."
iverilog -o tb_mel.vvp -g2005-sv \
    ../Mel_fbank.v ../Mel_mac.v ../Multiply_qx.v tb_Mel_fbank.v

if [ $? -ne 0 ]; then
    echo "[ERROR] Compilation failed!"
    exit 1
fi

if [ -f "tb_mel.vvp" ]; then
    echo "  [OK] Compilation successful"
else
    echo "[ERROR] tb_mel.vvp missing"
    exit 1
fi

echo "[Step 4] Running simulation..."
vvp tb_mel.vvp

if [ $? -ne 0 ]; then
    echo "[ERROR] Simulation failed!"
    exit 1
fi

echo "[Step 5] Checking result file..."
if [ -f "mel_output.txt" ]; then
    size=$(stat -f%z "mel_output.txt")
    echo "  [OK] mel_output.txt generated ($size bytes)"
else
    echo "  [FAIL] mel_output.txt not found"
fi

echo "===================================="
