import struct

import pytest

from tools.parse_pck import PCKParser


def test_pck_parser_invalid_magic(tmp_path):
    f = tmp_path / "test.pck"
    f.write_bytes(b"NOTM")
    parser = PCKParser(f)
    with pytest.raises(ValueError, match="missing GDPC magic"):
        parser.parse()


def test_pck_parser_empty(tmp_path):
    f = tmp_path / "empty.pck"
    # Header: Magic(4), PackVersion(4), GodotMajor(4), GodotMinor(4), GodotPatch(4),
    # Flags(4), FilesBase(8), Reserved(16*4), FileCount(4)
    header = b"GDPC"
    header += struct.pack("<I", 2)  # Pack version
    header += struct.pack("<III", 4, 6, 2)  # Godot version
    header += struct.pack("<I", 0)  # Flags
    header += struct.pack("<Q", 0)  # Files base
    header += b"\x00" * (16 * 4)  # Reserved
    header += struct.pack("<I", 0)  # File count

    f.write_bytes(header)

    parser = PCKParser(f)
    data = parser.parse()
    assert data["pack_version"] == 2
    assert data["godot_version"] == "4.6.2"
    assert data["file_count"] == 0
    assert len(data["files"]) == 0
