#!/usr/bin/env python3

import math

N = 512      # Number of FFT Points
NB = 16       # Number of Twiddle Data Bits

ND = len(str(2**(NB-1))) + 1  # Number of Decimal Digits
NX = (NB + 3) // 4             # Number of Hexadecimal Digits

XX = "x" * NX  # Hexadecimal Unknown Value String

print(f"//      wn_re = cos(-2pi*n/{N:2d})  ", end="")
print(f"        wn_im = sin(-2pi*n/{N:2d})")

for n in range(N):
    wr = math.cos(-2 * math.pi * n / N)
    wi = math.sin(-2 * math.pi * n / N)
    
    wr_d = int(math.floor(wr * 2**(NB-1) + 0.5))
    if wr_d == 2**(NB-1):
        wr_d -= 1
    
    wi_d = int(math.floor(wi * 2**(NB-1) + 0.5))
    if wi_d == 2**(NB-1):
        wi_d -= 1
    
    wr_u = wr_d if wr_d >= 0 else wr_d + 2**NB
    wi_u = wi_d if wi_d >= 0 else wi_d + 2**NB
    
    # Determine if value should be "don't care"
    dontcare = True
    if n < N // 4:
        dontcare = False
    elif (n < 2 * N // 4) and (n % 2 == 0):
        dontcare = False
    elif (n < 3 * N // 4) and (n % 3 == 0):
        dontcare = False
    
    if n == 0:
        wr_u = 0
    
    wr_s = XX if dontcare else f"{wr_u:0{NX}X}"
    wi_s = XX if dontcare else f"{wi_u:0{NX}X}"
    
    print(f"assign  wn_re[{n:2d}] = {NB}'h{wr_s};   ", end="")
    print(f"assign  wn_im[{n:2d}] = {NB}'h{wi_s};   ", end="")
    print(f"// {n:2d} {wr:7.3f} {wi:7.3f}")
