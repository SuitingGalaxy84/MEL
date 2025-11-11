"""
Generate test data for fake_mem module
This script creates fake_mem_init.txt with test patterns
"""

import numpy as np
import random

def generate_mem_init(filename="fake_mem_init.txt", mem_size=256):
    """
    Generate memory initialization file with test patterns
    
    Args:
        filename: Output file name
        mem_size: Size of memory in bytes
    """
    print(f"Generating memory initialization file: {filename}")
    print(f"Memory size: {mem_size} bytes")
    
    pattern_size = mem_size // 4  # Divide memory into 4 equal pattern sections
    
    with open(filename, 'w') as f:
        # Pattern 1: Sequential pattern (0x00, 0x01, 0x02, ...)
        for i in range(pattern_size):
            f.write(f"{i % 256:02X}\n")
        
        # Pattern 2: Inverse pattern (0xFF, 0xFE, 0xFD, ...)
        for i in range(pattern_size):
            f.write(f"{(0xFF - (i % 256)):02X}\n")
        
        # Pattern 3: Alternating pattern (0xAA, 0x55, 0xAA, 0x55, ...)
        for i in range(pattern_size):
            if i % 2 == 0:
                f.write("AA\n")
            else:
                f.write("55\n")
        
        # Pattern 4: Random data
        random.seed(42)  # For reproducibility
        for i in range(pattern_size):
            f.write(f"{random.randint(0, 255):02X}\n")
    
    print(f"✓ Generated {mem_size} bytes of test data")
    return filename

def generate_golden_output(mem_file="fake_mem_init.txt", output_file="golden_output.txt", mem_size=512):
    """
    Generate expected output based on memory contents
    Read 4 consecutive bytes starting from different addresses
    """
    print(f"\nGenerating golden output file: {output_file}")
    
    # Read memory initialization file
    mem_data = []
    with open(mem_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('//'):
                mem_data.append(int(line, 16))
    
    # Generate expected outputs for various program counter values
    test_addresses = [0, 4, 8, 12, 16, 32, 64, 96, 128, 192, 252, 256, 300, 304, 308]
    
    with open(output_file, 'w') as f:
        f.write("// Golden output for fake_mem testbench\n")
        f.write("// Format: Address -> 32-bit output (4 bytes concatenated)\n")
        for addr in test_addresses:
            if addr + 3 < len(mem_data):
                # Concatenate 4 bytes: {mem[addr], mem[addr+1], mem[addr+2], mem[addr+3]}
                byte0 = mem_data[addr]
                byte1 = mem_data[addr + 1]
                byte2 = mem_data[addr + 2]
                byte3 = mem_data[addr + 3]
                output_32bit = (byte0 << 24) | (byte1 << 16) | (byte2 << 8) | byte3
                f.write(f"// Addr {addr:3d}: {output_32bit:08X}\n")
                f.write(f"{output_32bit:08X}\n")
    
    print(f"✓ Generated golden output with {len(test_addresses)} test vectors")

if __name__ == "__main__":
    # Generate memory initialization file (512 bytes to match testbench)
    mem_file = generate_mem_init("fake_mem_init.txt", mem_size=512)
    
    # Generate golden output
    generate_golden_output(mem_file, "golden_output.txt", mem_size=512)
    
    print("\n" + "="*50)
    print("Memory data generation complete!")
    print("="*50)
