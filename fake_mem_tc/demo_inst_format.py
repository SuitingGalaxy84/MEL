"""
Demo usage of inst_format.py

This script demonstrates how to use the parse_inst_line function
to convert instruction format files.
Supports both binary (32-bit) and hex formats.
"""
from inst_format import parse_inst_line

# Example 1: Create a sample instruction file with binary format
sample_input_binary = "sample_instructions_binary.txt"
sample_output_binary = "sample_output_binary.txt"

print("Creating sample binary instruction file...")
with open(sample_input_binary, 'w') as f:
    f.write("// Sample binary instruction file (32-bit)\n")
    f.write("// Format: binary with spaces //Comment\n")
    f.write("\n")
    f.write("00000000 00000000 00000000 00000000 //NOP\n")
    f.write("000000 00001 00001 00001 00000 100010 //r1=0\n")
    f.write("000000 00010 00010 00010 00000 100010 //r2=0\n")
    f.write("001000 00001 00001 0000 0000 0000 0001 //r1=1\n")

print(f"Binary sample created: {sample_input_binary}")
print("\nBinary input content:")
with open(sample_input_binary, 'r') as f:
    print(f.read())

# Parse binary format
print("\nParsing binary instructions...")
count_binary = parse_inst_line(sample_input_binary, sample_output_binary)

print(f"\nBinary output content ({sample_output_binary}):")
with open(sample_output_binary, 'r') as f:
    print(f.read())

print(f"\nTotal binary instructions processed: {count_binary}")

# Example 2: Create a sample instruction file with hex format
sample_input_hex = "sample_instructions_hex.txt"
sample_output_hex = "sample_output_hex.txt"

print("\n" + "="*60)
print("Creating sample hex instruction file...")
with open(sample_input_hex, 'w') as f:
    f.write("// Sample hex instruction file\n")
    f.write("// Format: hex_hex_hex_hex //Comment\n")
    f.write("\n")
    f.write("1010_2020_3030_4040 //LOAD instruction\n")
    f.write("5050_6060_7070_8080 //STORE instruction\n")
    f.write("9090_A0A0_B0B0_C0C0 //ADD instruction\n")
    f.write("D0D0_E0E0_F0F0_0F0F //SUB instruction\n")

print(f"Hex sample created: {sample_input_hex}")
print("\nHex input content:")
with open(sample_input_hex, 'r') as f:
    print(f.read())

# Parse hex format
print("\nParsing hex instructions...")
count_hex = parse_inst_line(sample_input_hex, sample_output_hex)

print(f"\nHex output content ({sample_output_hex}):")
with open(sample_output_hex, 'r') as f:
    print(f.read())

print(f"\nTotal hex instructions processed: {count_hex}")
print(f"Total hex values extracted: {count_hex * 4}")
