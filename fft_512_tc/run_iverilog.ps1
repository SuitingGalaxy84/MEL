# PowerShell script to compile and run FFT512 testbench using iverilog
# Author: Auto-generated
# Date: November 12, 2025
Write-Host '--- Generating test data ---'
python verify_fft.py generate


Write-Host "====================================" -ForegroundColor Cyan
Write-Host "FFT512 Testbench - Icarus Verilog" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Change to the testbench directory
Set-Location -Path $PSScriptRoot

# Clean up previous simulation files
Write-Host "[Step 1] Cleaning up previous simulation files..." -ForegroundColor Yellow
if (Test-Path "tb512.vvp") {
    Remove-Item "tb512.vvp" -Force
    Write-Host "  - Removed tb512.vvp" -ForegroundColor Gray
}
if (Test-Path "output1.txt") {
    Remove-Item "output1.txt" -Force
    Write-Host "  - Removed output1.txt" -ForegroundColor Gray
}
if (Test-Path "output2.txt") {
    Remove-Item "output2.txt" -Force
    Write-Host "  - Removed output2.txt" -ForegroundColor Gray
}
Write-Host ""

# Compile the design
Write-Host "[Step 2] Compiling Verilog files..." -ForegroundColor Yellow
$compile_cmd = "iverilog -o tb512.vvp -g2005-sv " +
    "..\FFT512.v " +
    "..\SdfUnit.v " +
    "..\SdfUnit2.v " +
    "..\Butterfly.v " +
    "..\DelayBuffer.v " +
    "..\Multiply.v " +
    "..\Twiddle512.v " +
    "TB512.v"

Write-Host "  Command: $compile_cmd" -ForegroundColor Gray
Invoke-Expression $compile_cmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
    exit 1
}

if (Test-Path "tb512.vvp") {
    Write-Host "  [OK] Compilation successful" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Output file tb512.vvp not found!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Run the simulation
Write-Host "[Step 3] Running simulation..." -ForegroundColor Yellow
vvp tb512.vvp

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Simulation failed!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check results
Write-Host "[Step 4] Checking results..." -ForegroundColor Yellow
$success = $true

if (Test-Path "output1.txt") {
    $size1 = (Get-Item "output1.txt").Length
    Write-Host "  [OK] output1.txt generated ($size1 bytes)" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] output1.txt not found!" -ForegroundColor Red
    $success = $false
}

if (Test-Path "output2.txt") {
    $size2 = (Get-Item "output2.txt").Length
    Write-Host "  [OK] output2.txt generated ($size2 bytes)" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] output2.txt not found!" -ForegroundColor Red
    $success = $false
}
Write-Host ""

# Final status
Write-Host "====================================" -ForegroundColor Cyan
if ($success) {
    Write-Host "SIMULATION COMPLETED SUCCESSFULLY!" -ForegroundColor Green
} else {
    Write-Host "SIMULATION COMPLETED WITH ERRORS!" -ForegroundColor Red
}
Write-Host "====================================" -ForegroundColor Cyan

Write-Host "--- Verifying bit-reversal of FFT output ---" -ForegroundColor Yellow
python verify_fft.py verify
