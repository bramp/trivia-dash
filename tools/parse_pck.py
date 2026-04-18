#!/usr/bin/env python3
"""Parse a Godot .pck file and list contents with sizes."""

import struct
import sys
from pathlib import Path


class PCKParser:
    def __init__(self, path):
        self.path = Path(path)

    def parse(self):
        with open(self.path, "rb") as f:
            magic = f.read(4)
            if magic != b"GDPC":
                raise ValueError("Not a valid Godot PCK file (missing GDPC magic)")

            pack_version = struct.unpack("<I", f.read(4))[0]
            godot_ver = struct.unpack("<III", f.read(12))
            f.read(4)  # flags
            f.read(8)  # files_base
            f.read(16 * 4)  # reserved
            file_count = struct.unpack("<I", f.read(4))[0]

            ver = f"{godot_ver[0]}.{godot_ver[1]}.{godot_ver[2]}"
            files = []

            for _i in range(file_count):
                path_len = struct.unpack("<I", f.read(4))[0]
                p = f.read(path_len).rstrip(b"\x00").decode()
                offset = struct.unpack("<Q", f.read(8))[0]
                size = struct.unpack("<Q", f.read(8))[0]
                f.read(16)  # md5
                fl = struct.unpack("<I", f.read(4))[0]
                files.append({"path": p, "offset": offset, "size": size, "flags": fl})

            return {
                "pack_version": pack_version,
                "godot_version": ver,
                "file_count": file_count,
                "files": files,
            }


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "build/web/index.pck"
    if not Path(path).exists():
        print(f"Error: {path} not found")
        sys.exit(1)

    parser = PCKParser(path)
    try:
        data = parser.parse()
    except Exception as e:
        print(f"Error parsing PCK: {e}")
        sys.exit(1)

    msg = (
        f"PCK v{data['pack_version']}, Godot {data['godot_version']}, "
        f"{data['file_count']} files"
    )
    print(msg + "\n")

    total_font = 0
    total_other = 0
    for f in data["files"]:
        p = f["path"]
        size = f["size"]
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


if __name__ == "__main__":
    main()
