
def parse_instructions(raw_inst_pth, out_pth):
    '''
        Parse instruction lines and extract hex values.
        
        Supports two input formats:
        1. Binary format (32 bits): "000000 00001 00001 00001 00000 100010 //comment"
        2. Hex format with underscores: "1010_0101_1111_0000 //comment"
        
        Converts to separate hex bytes:
        0A
        05
        0F
        00
        
        Args:
            raw_inst_pth: Path to input file with instruction lines
            out_pth: Path to output file for extracted hex values
        
        Returns:
            Number of instructions processed
    '''
    instruction_count = 0
    
    with open(raw_inst_pth, 'r') as infile, open(out_pth, 'w') as outfile:
        for line in infile:
            # Strip whitespace and skip empty lines or comment-only lines
            line = line.strip()
            if not line or line.startswith('//'):
                continue
            
            # Extract the data part before the comment
            if '//' in line:
                data_part = line.split('//')[0].strip()
            else:
                data_part = line.strip()
            
            # Skip if no valid data
            if not data_part:
                continue
            
            # Check if input is binary (contains only 0, 1, and spaces)
            if all(c in '01 ' for c in data_part):
                # Binary format: remove spaces and convert to hex
                binary_str = data_part.replace(' ', '')
                
                # Validate it's 32 bits
                if len(binary_str) != 32:
                    print(f"Warning: Binary string not 32 bits: {binary_str} (length: {len(binary_str)})")
                    continue
                
                # Convert binary to hex (8 hex digits = 32 bits)
                hex_value = hex(int(binary_str, 2))[2:].upper().zfill(8)
            else:
                # Hex format: remove underscores
                hex_value = data_part.replace('_', '').upper()
            
            # Write each byte (2 hex digits) on a separate line
            for i in range(0, len(hex_value), 2):
                if i + 1 < len(hex_value):
                    outfile.write(hex_value[i:i+2] + '\n')
            
            instruction_count += 1
    
    return instruction_count

# Alias for backward compatibility
parse_inst_line = parse_instructions

if __name__ == "__main__":
    instr_count = parse_instructions("raw_instructions.txt", "parsed_instructions.txt")
    print(f"Processed {instr_count} instructions.")


