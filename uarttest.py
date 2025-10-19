import sys
import time
import serial
import random

SERIAL_PORT = "COM3" # check device manager and change to that com port
BAUD_RATE = 115200
NUM_TESTS = 20

def send_and_receive(data32, timeout=5.0):
    "Send 32 bytes and read two 16-byte replies."
    with serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=timeout) as ser:
        try:
            ser.flush()
            # send the 32 bytes
            ser.write(bytes(data32))

            # read 16 bytes * 2
            part1 = ser.read(16)
            part2 = ser.read(16)


            return bytes(part1), bytes(part2)
        finally:
            ser.close()

def main():
    
    for i in range(NUM_TESTS):
        # prepare 32 bytes to send
        data32 = [random.randint(0, 255) for _ in range(32)]
        #print("Sending 32 bytes:", data32)

        part1, part2 = send_and_receive(data32, timeout=5.0)

        #print("Part1:", list(part1))
        #print("Part2:", list(part2))

        # the wrapper transmits first 128 bits then second 128 bits.
        expected_first = bytes(data32[0:16])   # bytes 0..15
        expected_second = bytes(data32[16:32]) # bytes 16..31

        if part1 == expected_first and part2 == expected_second:
            print("Pass: Received two parts match original 32-byte message.")
        else:
            print("Fail: Received data does not match original.")
            if part1 != expected_first:
                print(" - First 16 bytes mismatch.")
            if part2 != expected_second:
                print(" - Second 16 bytes mismatch.")

if __name__ == "__main__":
    main()