import serial

SERIAL_PORT = "COM3"   #check device manager and change to that com port
BAUD_RATE = 115200

def xtime(x):
    "Multiply by x in GF(2^8) using AES polynomial 0x11B."
    x <<= 1
    if x & 0x100:
        x ^= 0x11B
    return x & 0xFF


def gf_mul(a, b):
    "Multiply two numbers in GF(2^8)."
    res = 0
    for _ in range(8):
        if b & 1:
            res ^= a
        hi = a & 0x80
        a = (a << 1) & 0xFF
        if hi:
            a ^= 0x1B
        b >>= 1
    return res


def gf_inv(a):
    "Multiplicative inverse in GF(2^8)."
    if a == 0:
        return 0
    for b in range(1, 256):
        if gf_mul(a, b) == 1:
            return b
    return 0


def affine_transform(x):
    "AES affine transformation."
    s = 0
    for i in range(8):
        bit = (
            ((x >> i) & 1)
            ^ ((x >> ((i + 4) % 8)) & 1)
            ^ ((x >> ((i + 5) % 8)) & 1)
            ^ ((x >> ((i + 6) % 8)) & 1)
            ^ ((x >> ((i + 7) % 8)) & 1)
            ^ ((0x63 >> i) & 1)
        )
        s |= (bit << i)
    return s


def aes_sbox(byte_in):
    "Compute AES S-box value dynamically."
    inv = gf_inv(byte_in)
    return affine_transform(inv)

def run_tests():
    with serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1) as ser:
        total = 0
        passed = 0

        for val in range(256):
            ser.write(bytes([val]))       #send test byte
            expected = aes_sbox(val)      #calculate expected S-box value
            res = ser.read(1)             #read one byte back

            if len(res) == 0:
                print(f"[{val:02X}] No response from FPGA")
                continue

            got = res[0]
            ok = (got == expected)
            print(f"in=0x{val:02X} -> expected=0x{expected:02X}, got=0x{got:02X} | {'PASS' if ok else 'FAIL'}")

            total += 1
            passed += ok

        print(f"\nSummary: {passed}/{total} passed ({100*passed/total:.1f}%)")


if __name__ == "__main__":
    run_tests()
