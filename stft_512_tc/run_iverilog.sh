#!/bin/bash

echo "Remove Old Compilation Files ..."
if [ -e tb_stft_512.vvp ]; then
    rm -f tb_stft_512.vvp
else
    echo "No existing tb_stft_512.vvp to remove."
fi

echo 'Compiling Verilog files ...'
iverilog -o tb_stft_512.vvp -g2005-sv \
    ../STFT.v \
    ../Window_lut.v \
    ../cir_buffer.v \
    ../HannWin480.v \
    ../FFT512.v \
    ../SdfUnit.v \
    ../SdfUnit2.v \
    ../Butterfly.v \
    ../DelayBuffer.v \
    ../Multiply.v \
    ../Twiddle512.v \
    # TB_STFT_512.v
