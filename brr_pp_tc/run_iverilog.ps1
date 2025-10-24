Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Bit-Reversal Testbench - Icarus Verilog" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

Write-Host "[Step 1] Compiling Verilog files..." -ForegroundColor Yellow

Set-Location -Path $PSScriptRoot
$compile_cmd = "iverilog -o tb_brr_pp.vvp -g2005-sv " +
    "..\BitRevReorder.v tb_BRR_PP.v"

Write-Host "  Command: $compile_cmd" -ForegroundColor Gray
Invoke-Expression $compile_cmd

Write-Host "[Step 2] Running simulation..." -ForegroundColor Yellow
vvp tb_brr_pp.vvp
