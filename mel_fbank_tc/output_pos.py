# Read mac_bits to understand the pattern
with open('convert/mac_bits.txt', 'r') as f:
    mac_bits = [int(line.strip(), 2) for line in f if line.strip()]

DISP_LEN = 50  # Number of FFT bins to display
print(f'Total FFT bins: {len(mac_bits)}')
print(f'\nMAC bits pattern (first {DISP_LEN} bins):')
print('Index  MAC_Bits  MAC_1_bit MAC_2_bit')
print('-' * 50)

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

    print(f'{i:5d}      {mac_bit:02b}      {mac_1_bit}         {mac_2_bit}      {output_type}')

    prev_mac_1 = mac_1_bit
    prev_mac_2 = mac_2_bit

print(f'\nOutputs in first {DISP_LEN} bins: {output_count}')
