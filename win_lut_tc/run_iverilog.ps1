# Window LUT Testbench - Run Script (PowerShell)
# This script runs the Icarus Verilog simulation for the Window_lut module

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Window LUT Testbench - Icarus Verilog" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Check if input.txt exists
if (-Not (Test-Path "input.txt")) {
    Write-Host "`nGenerating input data..." -ForegroundColor Yellow
    python generate_input.py
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to generate input data" -ForegroundColor Red
        exit 1
    }
}

# Compile the Verilog files
Write-Host "`nCompiling Verilog files..." -ForegroundColor Yellow

$verilog_files = @(
    "..\cir_buffer.v",
    "..\HannWin480.v",
    "..\Multiply.v",
    "..\Window_lut.v",
    "..\S2Sram.v",
    "tb_Window_lut.v"
)

# Check if all files exist
foreach ($file in $verilog_files) {
    if (-Not (Test-Path $file)) {
        Write-Host "Error: File not found: $file" -ForegroundColor Red
        exit 1
    }
}

# Run iverilog
iverilog -g2012 -o tb_window_lut.vvp $verilog_files

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nCompilation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Compilation successful!" -ForegroundColor Green

# Run the simulation
Write-Host "`nRunning simulation..." -ForegroundColor Yellow
vvp tb_window_lut.vvp

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nSimulation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nSimulation completed!" -ForegroundColor Green

# Run verification
Write-Host "`nRunning verification..." -ForegroundColor Yellow
python verify.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nVerification script encountered errors" -ForegroundColor Red
    exit 1
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "Test completed!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
