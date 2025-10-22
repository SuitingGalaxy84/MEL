# PowerShell script to compile and run FFT128 testbench using iverilog
# Author: Auto-generated
# Date: October 22, 2025

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "FFT128 Testbench - Icarus Verilog" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Change to the testbench directory
Set-Location -Path $PSScriptRoot

# Clean up previous simulation files
Write-Host "[Step 1] Cleaning up previous simulation files..." -ForegroundColor Yellow
if (Test-Path "tb128.vvp") {
    Remove-Item "tb128.vvp" -Force
    Write-Host "  - Removed tb128.vvp" -ForegroundColor Gray
}
if (Test-Path "output4.txt") {
    Remove-Item "output4.txt" -Force
    Write-Host "  - Removed output4.txt" -ForegroundColor Gray
}
if (Test-Path "output5.txt") {
    Remove-Item "output5.txt" -Force
    Write-Host "  - Removed output5.txt" -ForegroundColor Gray
}
Write-Host ""

# Compile the design
Write-Host "[Step 2] Compiling Verilog files..." -ForegroundColor Yellow
$compile_cmd = "iverilog -o tb128.vvp -g2005-sv " +
    "..\FFT128.v " +
    "..\SdfUnit_TC.v " +
    "..\SdfUnit2.v " +
    "..\Butterfly.v " +
    "..\DelayBuffer.v " +
    "..\Multiply.v " +
    "..\TwiddleConvert8.v " +
    "..\Twiddle128.v " +
    "TB128.v"

Write-Host "  Command: $compile_cmd" -ForegroundColor Gray
Invoke-Expression $compile_cmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red
    exit 1
}

if (Test-Path "tb128.vvp") {
    Write-Host "  [OK] Compilation successful" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Output file tb128.vvp not found!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Run the simulation
Write-Host "[Step 3] Running simulation..." -ForegroundColor Yellow
vvp tb128.vvp

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Simulation failed!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check results
Write-Host "[Step 4] Checking results..." -ForegroundColor Yellow
$success = $true

if (Test-Path "output4.txt") {
    $size4 = (Get-Item "output4.txt").Length
    Write-Host "  [OK] output4.txt generated ($size4 bytes)" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] output4.txt not found!" -ForegroundColor Red
    $success = $false
}

if (Test-Path "output5.txt") {
    $size5 = (Get-Item "output5.txt").Length
    Write-Host "  [OK] output5.txt generated ($size5 bytes)" -ForegroundColor Green
} else {
    Write-Host "  [FAIL] output5.txt not found!" -ForegroundColor Red
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
