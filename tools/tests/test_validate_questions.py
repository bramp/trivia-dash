import json

from tools.validate_questions import validate_file


def test_validate_file_valid(tmp_path):
    d = tmp_path / "questions"
    d.mkdir()
    f = d / "test.json"
    content = [
        {"question": "What is 1+1?", "answer": "2", "distractors": ["1", "3", "4"]}
    ]
    f.write_text(json.dumps(content))

    # Mocking QUESTIONS_DIR inside validate_questions is tricky because it's a
    # global Path. However, validate_file calculates 'rel' using QUESTIONS_DIR.
    # For unit testing, we can monkeypatch QUESTIONS_DIR if needed,
    # but let's see if we can just pass the path.

    import tools.validate_questions

    tools.validate_questions.QUESTIONS_DIR = d

    errors = validate_file(f)
    assert not errors


def test_validate_file_invalid_json(tmp_path):
    d = tmp_path / "questions"
    d.mkdir()
    f = d / "invalid.json"
    f.write_text("not json")

    import tools.validate_questions

    tools.validate_questions.QUESTIONS_DIR = d

    errors = validate_file(f)
    assert len(errors) == 1
    assert "invalid JSON" in errors[0]


def test_validate_file_too_long(tmp_path):
    d = tmp_path / "questions"
    d.mkdir()
    f = d / "long.json"
    content = [
        {
            "question": "A" * 200,  # Max is 150
            "answer": "B",
            "distractors": ["C", "D", "E"],
        }
    ]
    f.write_text(json.dumps(content))

    import tools.validate_questions

    tools.validate_questions.QUESTIONS_DIR = d

    errors = validate_file(f)
    assert len(errors) == 1
    assert "question too long" in errors[0]


def test_validate_file_duplicate_answer(tmp_path):
    d = tmp_path / "questions"
    d.mkdir()
    f = d / "dup.json"
    content = [
        {
            "question": "Valid question?",
            "answer": "Same",
            "distractors": ["Same", "Other", "Another"],
        }
    ]
    f.write_text(json.dumps(content))

    import tools.validate_questions

    tools.validate_questions.QUESTIONS_DIR = d

    errors = validate_file(f)
    assert len(errors) == 1
    assert "duplicate answer" in errors[0]
