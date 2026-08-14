# -*- coding: utf-8 -*-
import serial
import time

def crc(data: bytes) -> int:
    s = 0
    for b in data:
        s ^= b
    return s & 0xFF

def frame(payload: bytes) -> bytes:
    body = bytes([len(payload)]) + payload
    return bytes([0x02]) + body + bytes([crc(body)])

def xfer(ser: serial.Serial, payload: bytes, timeout: float = 1.0):
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    ser.write(frame(payload))
    ser.flush()
    t0 = time.time()
    while time.time() - t0 < timeout:
        b = ser.read(1)
        if not b:
            continue
        if b == b'\x06':
            break
        if b == b'\x15':
            return 'NAK', b''
    else:
        return 'no-ack', b''
    t0 = time.time()
    while time.time() - t0 < timeout:
        b = ser.read(1)
        if b == b'\x02':
            break
    else:
        return 'no-stx', b''
    ln = ser.read(1)
    if not ln:
        return 'no-len', b''
    n = ln[0]
    rest = ser.read(n + 1)
    return 'ok', bytes([0x02]) + ln + rest

def main():
    ser = serial.Serial('COM12', 115200, timeout=0.2)
    try:
        for name, pl in [
            ('F7', bytes([0xF7, 0x01])),
            ('FEE7', bytes([0xFE, 0xE7, 0, 0, 0, 0])),
            ('11', bytes([0x11, 0x1E, 0, 0, 0])),
        ]:
            st, ans = xfer(ser, pl)
            print(name, st, ans.hex(' ') if ans else '')
            if ans and len(ans) > 3:
                payload = ans[2:2 + ans[1]]
                print(' payload', payload.hex(' '))
                if name == 'F7' and len(payload) >= 10:
                    flags = int.from_bytes(payload[2:10], 'little')
                    print(' flags', hex(flags),
                          'bit23', bool(flags & (1 << 23)),
                          'bit57', bool(flags & (1 << 57)),
                          'bit58', bool(flags & (1 << 58)))
                if name == '11' and len(payload) >= 40:
                    # FMFlags offset in classic 11h: after cmd/err/... 
                    # payload[0]=cmd, [1]=err, ... FMFlags at index 31 (0-based in payload)
                    print(' len', len(payload), 'fmflags', payload[31] if len(payload) > 31 else None)
    finally:
        ser.close()

if __name__ == '__main__':
    main()
