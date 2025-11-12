import math

# Generate 512-point twiddle factor table
with open("twiddle512.txt", "w") as f:
    for i in range(512):
        cos_val = math.cos(-2*math.pi*i/512)
        sin_val = math.sin(-2*math.pi*i/512)
        
        # Convert to Q15 format (16-bit signed fixed point)
        re_hex = int(cos_val * 32767) & 0xFFFF
        im_hex = int(sin_val * 32767) & 0xFFFF
        
        f.write(f"assign wn_re[{i:3d}] = 16'h{re_hex:04X};    assign wn_im[{i:3d}] = 16'h{im_hex:04X};   // {i:d} {cos_val:6.3f} {sin_val:6.3f}\n")
f.close()