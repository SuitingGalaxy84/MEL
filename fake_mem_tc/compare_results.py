vals_old = [66051, 67438087, 134810123, 202182159, 269554195, 539042339, 4294901244, 3755924956, 2857740885, 957123709, 1467831276]
vals_new = [66051, 67438087, 134810123, 202182159, 269554195, 539042339, 1078018627, 1616994915, 4294901244, 3216948668, 2206368128]

print("="*70)
print("COMPARISON: Old (256B with circular read) vs New (512B fixed)")
print("="*70)
print(f"{'Index':<8} {'OLD (256B)':<20} {'NEW (512B)':<20} {'Status'}")
print("-"*70)

for i in range(11):
    status = "SAME" if vals_old[i] == vals_new[i] else "CHANGED (FIXED!)"
    print(f"  [{i:2d}]  0x{vals_old[i]:08X} ({vals_old[i]:<10})  0x{vals_new[i]:08X} ({vals_new[i]:<10})  {status}")

print("\n" + "="*70)
print("Key addresses that were affected by circular read:")
print("="*70)
print("  Address 64:  OLD=0xFFFEFDFC (wrong!) -> NEW=0x40414243 (correct!)")
print("  Address 96:  OLD=0xDFDEDDDC (wrong!) -> NEW=0x60616263 (correct!)")
print("  Address 192: OLD=0x390C8C7D (wrong!) -> NEW=0xBFBEBDBC (correct!)")
print("  Address 252: OLD=0x577D53EC (wrong!) -> NEW=0x83828180 (correct!)")
print("\n✓ Circular read issue FIXED by expanding memory from 256 to 512 bytes!")
