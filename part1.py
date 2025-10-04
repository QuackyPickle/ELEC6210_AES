import serial
import random

SERIAL_PORT = "COM3" #check device manager and change to that com port
BAUD_RATE = 115200
NUM_TESTS = 20

def run_tests():
    with serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1) as ser:

        for i in range(NUM_TESTS):
            a1 = random.randint(0, 15) #random numbers
            a2 = random.randint(0, 15)

            test_byte = (a1 << 4) | a2
            ser.write(bytes([test_byte]))

            expected_sum = a1 + a2

            res = ser.read(1) #read one byte
            if len(res) == 0:
                print(f"[{i}] No response from FPGA")
                continue

            result = res[0]

            print(f"[{i}] {a1}+{a2}={expected_sum}, got={result} | "
                  f"{'Pass' if result == expected_sum else 'Fail'}")

if __name__ == "__main__":
    run_tests()
