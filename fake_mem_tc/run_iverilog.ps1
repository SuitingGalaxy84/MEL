Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Fake Memory Testbench - Icarus Verilog" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Set location to script directory
Set-Location -Path $PSScriptRoot

# Step 0: Generate test data
Write-Host "[Step 0] Generating memory initialization data..." -ForegroundColor Yellow
python generate_mem_data.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error generating test data!" -ForegroundColor Red
    exit 1
}

# Step 1: Compile Verilog files
Write-Host "`n[Step 1] Compiling Verilog files..." -ForegroundColor Yellow

$compile_cmd = "iverilog -o tb_fake_mem.vvp -g2005-sv " +
    "..\fake_mem.v tb_fake_mem.v"

Write-Host "  Command: $compile_cmd" -ForegroundColor Gray
Invoke-Expression $compile_cmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "  ✓ Compilation successful" -ForegroundColor Green

# Step 2: Run simulation
Write-Host "`n[Step 2] Running simulation..." -ForegroundColor Yellow
vvp tb_fake_mem.vvp | Tee-Object -FilePath "simulation.log"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Simulation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "  ✓ Simulation completed" -ForegroundColor Green

# Step 3: Display results
Write-Host "`n[Step 3] Test Results:" -ForegroundColor Yellow
Write-Host "  - Simulation log saved to: simulation.log" -ForegroundColor Gray
Write-Host "  - Output data saved to: output.txt" -ForegroundColor Gray
Write-Host "  - Golden output saved to: golden_output.txt" -ForegroundColor Gray
Write-Host "  - Waveform saved to: tb_fake_mem.vcd" -ForegroundColor Gray

Write-Host "`n====================================" -ForegroundColor Cyan
Write-Host "Testbench execution complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Cyan

python verify.py