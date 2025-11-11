#!/bin/bash

echo "===================================="
echo "Fake Memory Testbench - Icarus Verilog"
echo "===================================="

# Set location to script directory
cd "$(dirname "$0")"

# Step 0: Generate test data
echo "[Step 0] Generating memory initialization data..."
python3 generate_mem_data.py

if [ $? -ne 0 ]; then
    echo "Error generating test data!"
    exit 1
fi

# Step 1: Compile Verilog files
echo ""
echo "[Step 1] Compiling Verilog files..."

compile_cmd="iverilog -o tb_fake_mem.vvp -g2005-sv ../fake_mem.v tb_fake_mem.v"

echo "  Command: $compile_cmd"
eval $compile_cmd

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

echo "  ✓ Compilation successful"

# Step 2: Run simulation
echo ""
echo "[Step 2] Running simulation..."
vvp tb_fake_mem.vvp | tee simulation.log

if [ $? -ne 0 ]; then
    echo "Simulation failed!"
    exit 1
fi

echo "  ✓ Simulation completed"

# Step 3: Display results
echo ""
echo "[Step 3] Test Results:"
echo "  - Simulation log saved to: simulation.log"
echo "  - Output data saved to: output.txt"
echo "  - Golden output saved to: golden_output.txt"
echo "  - Waveform saved to: tb_fake_mem.vcd"

echo ""
echo "===================================="
echo "Testbench execution complete!"
echo "===================================="

python verify.py
