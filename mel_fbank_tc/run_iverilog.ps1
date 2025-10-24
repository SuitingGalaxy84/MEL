# PowerShell script to compile and run MEL_FBANK testbench using iverilog
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "MEL_FBANK Testbench - Icarus Verilog" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

Set-Location -Path $PSScriptRoot

Write-Host "[Step 1] Generating mel filterbank coefficients..." -ForegroundColor Yellow
python convert/encode_mel_fb.py
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Failed to generate mel filterbank coefficients!" -ForegroundColor Red; exit 1 }
Write-Host "  [OK] Generated mel filterbank coefficients" -ForegroundColor Green

Write-Host "[Step 2] Generating q15 test data..." -ForegroundColor Yellow
python data_gen_q15.py
if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Failed to generate q15 test data!" -ForegroundColor Red; exit 1 }
Write-Host "  [OK] Generated q15 test data" -ForegroundColor Green

# Clean previous outputs
if (Test-Path "mel_output.txt") { Remove-Item "mel_output.txt" -Force }
if (Test-Path "tb_Mel_fbank.vcd") { Remove-Item "tb_Mel_fbank.vcd" -Force }

Write-Host "[Step 3] Compiling Verilog files..." -ForegroundColor Yellow
$compile_cmd = "iverilog -o tb_mel.vvp -g2005-sv " +
    "..\Mel_fbank.v ..\Mel_mac.v ..\Multiply_qx.v tb_Mel_fbank.v"

Write-Host "  Command: $compile_cmd" -ForegroundColor Gray
Invoke-Expression $compile_cmd

if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red; exit 1 }

if (Test-Path "tb_mel.vvp") { Write-Host "  [OK] Compilation successful" -ForegroundColor Green } else { Write-Host "[ERROR] tb_mel.vvp missing" -ForegroundColor Red; exit 1 }

Write-Host "[Step 4] Running simulation..." -ForegroundColor Yellow
vvp tb_mel.vvp

if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Simulation failed!" -ForegroundColor Red; exit 1 }

Write-Host "[Step 5] Checking result file..." -ForegroundColor Yellow
if (Test-Path "mel_output.txt") { $size = (Get-Item "mel_output.txt").Length; Write-Host "  [OK] mel_output.txt generated ($size bytes)" -ForegroundColor Green } else { Write-Host "  [FAIL] mel_output.txt not found" -ForegroundColor Red }

Write-Host "====================================" -ForegroundColor Cyan
