# PowerShell script to compile and run MEL_FBANK testbench using iverilog
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "MEL_FBANK Testbench - Icarus Verilog" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

Set-Location -Path $PSScriptRoot

# Clean previous outputs
if (Test-Path "mel_output.txt") { Remove-Item "mel_output.txt" -Force }
if (Test-Path "tb_Mel_fbank.vcd") { Remove-Item "tb_Mel_fbank.vcd" -Force }

Write-Host "[Step 1] Compiling Verilog files..." -ForegroundColor Yellow
$compile_cmd = "iverilog -o tb_mel.vvp -g2005-sv " +
    "..\Mel_fbank.v ..\Mel_mac.v ..\Multiply_qx.v tb_Mel_fbank.v"

Write-Host "  Command: $compile_cmd" -ForegroundColor Gray
Invoke-Expression $compile_cmd

if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Compilation failed!" -ForegroundColor Red; exit 1 }

if (Test-Path "tb_mel.vvp") { Write-Host "  [OK] Compilation successful" -ForegroundColor Green } else { Write-Host "[ERROR] tb_mel.vvp missing" -ForegroundColor Red; exit 1 }

Write-Host "[Step 2] Running simulation..." -ForegroundColor Yellow
vvp tb_mel.vvp

if ($LASTEXITCODE -ne 0) { Write-Host "[ERROR] Simulation failed!" -ForegroundColor Red; exit 1 }

Write-Host "[Step 3] Checking result file..." -ForegroundColor Yellow
if (Test-Path "mel_output.txt") { $size = (Get-Item "mel_output.txt").Length; Write-Host "  [OK] mel_output.txt generated ($size bytes)" -ForegroundColor Green } else { Write-Host "  [FAIL] mel_output.txt not found" -ForegroundColor Red }

Write-Host "====================================" -ForegroundColor Cyan
