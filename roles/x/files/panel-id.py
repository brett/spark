#!/usr/bin/env python3
# Print the internal panel's EDID ID (PNP vendor + product code), e.g. BOE0CB4.
import glob

for path in glob.glob("/sys/class/drm/card*-eDP-*/edid"):
    with open(path, "rb") as f:
        edid = f.read()
    if edid:
        vendor = int.from_bytes(edid[8:10], "big")
        product = int.from_bytes(edid[10:12], "little")
        print("".join(chr(64 + (vendor >> s & 31)) for s in (10, 5, 0)) + f"{product:04X}")
        break
