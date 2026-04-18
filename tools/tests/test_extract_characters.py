import json

from tools.extract_characters import extract_from_json, extract_from_tscn


def test_extract_from_json(tmp_path):
    f = tmp_path / "test.json"
    content = [
        {
            "question": "ABC",
            "answer": "DEF",
            "distractors": ["GHI"],
            "alternative_answers": ["JKL"],
        }
    ]
    f.write_text(json.dumps(content))

    chars = extract_from_json(f)
    assert chars == set("ABCDEFGHIJKL")


def test_extract_from_tscn(tmp_path):
    f = tmp_path / "test.tscn"
    # Simplified TSCN format
    content = 'text = "Hello World"\ntext = "Godot"'
    f.write_text(content)

    chars = extract_from_tscn(f)
    assert chars == set("Hello WorldGodot")
