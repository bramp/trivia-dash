#!/usr/bin/env python3
"""Parse a Godot .pck file and list contents with sizes."""

import struct
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "build/web/index.pck"

with open(path, "rb") as f:
    magic = f.read(4)
    pack_version = struct.unpack("<I", f.read(4))[0]
    godot_ver = struct.unpack("<III", f.read(12))
    flags = struct.unpack("<I", f.read(4))[0]
    files_base = struct.unpack("<Q", f.read(8))[0]
    f.read(16 * 4)  # reserved
    file_count = struct.unpack("<I", f.read(4))[0]

    ver = f"{godot_ver[0]}.{godot_ver[1]}.{godot_ver[2]}"
    print(f"PCK v{pack_version}, Godot {ver}, {file_count} files\n")

    total_font = 0
    total_other = 0
    for _i in range(file_count):
        path_len = struct.unpack("<I", f.read(4))[0]
        p = f.read(path_len).rstrip(b"\x00").decode()
        offset = struct.unpack("<Q", f.read(8))[0]
        size = struct.unpack("<Q", f.read(8))[0]
        f.read(16)  # md5
        fl = struct.unpack("<I", f.read(4))[0]

        is_font = "font" in p.lower() or "Noto" in p
        if is_font:
            total_font += size
        else:
            total_other += size
        label = "FONT" if is_font else "    "
        sz = (
            f"{size / 1024 / 1024:.2f} MB" if size > 500000 else f"{size / 1024:.1f} KB"
        )
        print(f"  {label} {p} ({sz})")

    print(f"\nFont total:  {total_font / 1024 / 1024:.2f} MB")
    print(f"Other total: {total_other / 1024:.1f} KB")
    print(f"Grand total: {(total_font + total_other) / 1024 / 1024:.2f} MB")
