# PowerShell script to run BitRevReorder testbench with Icarus Verilog

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Bit-Reversal Reorder Simulation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Compile Verilog files
Write-Host "Compiling Verilog files..." -ForegroundColor Yellow
iverilog -o tb_bitrev.vvp tb_BitRevReorder.v BitRevReorder.v

if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Compilation successful!" -ForegroundColor Green
Write-Host ""

# Run simulation
Write-Host "Running simulation..." -ForegroundColor Yellow
vvp tb_bitrev.vvp

if ($LASTEXITCODE -ne 0) {
    Write-Host "Simulation failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Simulation complete!" -ForegroundColor Green
Write-Host ""

# Check if VCD file was created
if (Test-Path "tb_bitrev.vcd") {
    Write-Host "Waveform saved to: tb_bitrev.vcd" -ForegroundColor Cyan
    Write-Host "Open with GTKWave to view waveforms" -ForegroundColor Cyan
} else {
    Write-Host "Warning: VCD file not created" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
