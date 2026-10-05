#!/usr/bin/env python3
"""Write the SSGBerk reference image: 64x64 8-bit RGB PNG, four horizontal bands.

Usage: make_reference_png.py <out-path>

Deterministic: stdlib only, no ancillary chunks, fixed compression level.
Bands (16 rows each): #2f5bd3, #f2f4f8, #1d2330, #d8dde7.
"""
import struct
import sys
import zlib

SIZE = 64
BANDS = ("2f5bd3", "f2f4f8", "1d2330", "d8dde7")


def chunk(ctype, data):
    body = ctype + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def build():
    raw = b"".join(
        b"\x00" + bytes.fromhex(BANDS[y * len(BANDS) // SIZE]) * SIZE for y in range(SIZE)
    )
    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def main(argv):
    if len(argv) != 2:
        sys.stderr.write("usage: make_reference_png.py <out-path>\n")
        return 2
    with open(argv[1], "wb") as fh:
        fh.write(build())
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
