# Read mac_bits to understand the pattern
with open('mel_fbank_tc/convert/mac_bits.txt', 'r') as f:
    mac_bits = [int(line.strip(), 2) for line in f if line.strip()]

with open('mel_fbank_tc/mac_output.txt', 'w') as log_file:
    DISP_LEN = 10000  # Number of FFT bins to display
    log_file.write(f'Total FFT bins: {len(mac_bits)}\n')
    log_file.write(f'\nMAC bits pattern (first {DISP_LEN} bins):\n')
    log_file.write('Index  MAC_Bits  MAC_1_bit MAC_2_bit\n')
    log_file.write('-' * 50 + '\n')


    prev_mac_1 = 0
    prev_mac_2 = 1

    output_count = 0
    for i in range(min(DISP_LEN, len(mac_bits))):
        mac_bit = mac_bits[i]
        mac_1_bit = (mac_bit >> 1) & 1
        mac_2_bit = mac_bit & 1

        mac_1_xor = mac_1_bit ^ prev_mac_1
        mac_2_xor = mac_2_bit ^ prev_mac_2

        xor_bits = (mac_1_xor << 1) | mac_2_xor
        output_type = ''

        if xor_bits == 0b01:  # MAC_2 transition -> output
            output_type = '-> Output (MAC_2)'
            output_count += 1
        elif xor_bits == 0b10:  # MAC_1 transition -> output  
            output_type = '-> Output (MAC_1)'
            output_count += 1

        log_file.write(f'{i:5d}      {mac_bit:02b}      {mac_1_bit}         {mac_2_bit}      {output_type}\n')
        prev_mac_1 = mac_1_bit
        prev_mac_2 = mac_2_bit

    log_file.write(f'\nOutputs in first {DISP_LEN} bins: {output_count}\n')
