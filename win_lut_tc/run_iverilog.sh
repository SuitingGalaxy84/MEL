#!/bin/bash
# Window LUT Testbench - Run Script (Bash)
# This script runs the Icarus Verilog simulation for the Window_lut module

echo "======================================"
echo "Window LUT Testbench - Icarus Verilog"
echo "======================================"

# Check if input.txt exists
if [ ! -f "input.txt" ]; then
    echo ""
    echo "Generating input data..."
    python3 generate_input.py
    if [ $? -ne 0 ]; then
        echo "Error: Failed to generate input data"
        exit 1
    fi
fi

# Compile the Verilog files
echo ""
echo "Compiling Verilog files..."

VERILOG_FILES=(
    "../cir_buffer.v"
    "../HannWin480.v"
    "../Multiply.v"
    "../Window_lut.v"
    "../S2Sram.v"
    "tb_Window_lut.v"
)

# Check if all files exist
for file in "${VERILOG_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file"
        exit 1
    fi
done

# Run iverilog
iverilog -g2012 -o tb_window_lut.vvp "${VERILOG_FILES[@]}"

if [ $? -ne 0 ]; then
    echo ""
    echo "Compilation failed!"
    exit 1
fi

echo "Compilation successful!"

# Run the simulation
echo ""
echo "Running simulation..."
vvp tb_window_lut.vvp

if [ $? -ne 0 ]; then
    echo ""
    echo "Simulation failed!"
    exit 1
fi

echo ""
echo "Simulation completed!"

Run verification
echo ""
echo "Running verification..."
python3 verify.py

if [ $? -ne 0 ]; then
    echo ""
    echo "Verification script encountered errors"
    exit 1
fi

echo ""
echo "======================================"
echo "Test completed!"
echo "======================================"
