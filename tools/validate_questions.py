#!/usr/bin/env python3
"""Validate all question data files for structure and text length constraints.

Ensures every question will display correctly in the game UI at all supported
resolutions. Run via: make validate-questions
"""

import json
import sys
from pathlib import Path

QUESTIONS_DIR = Path(__file__).resolve().parent.parent / "data" / "questions"

# Maximum character lengths that the UI can render without overflow.
MAX_QUESTION_LENGTH = 150
MAX_ANSWER_LENGTH = 100

# Required fields in each question object.
REQUIRED_FIELDS = {"question", "answer", "distractors"}

DISTRACTOR_COUNT = 3


def validate_file(path: Path) -> list[str]:
    """Validate a single question file. Returns a list of error strings."""
    errors: list[str] = []
    rel = path.relative_to(QUESTIONS_DIR)

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        return [f"{rel}: invalid JSON: {e}"]

    if not isinstance(data, list):
        return [f"{rel}: root must be a JSON array"]

    for i, q in enumerate(data):
        prefix = f"{rel}[{i}]"

        if not isinstance(q, dict):
            errors.append(f"{prefix}: entry must be an object")
            continue

        # Check required fields.
        for field in REQUIRED_FIELDS:
            if field not in q:
                errors.append(f"{prefix}: missing required field '{field}'")

        # Validate question text.
        question_text = q.get("question", "")
        if not isinstance(question_text, str) or not question_text.strip():
            errors.append(f"{prefix}: 'question' must be a non-empty string")
        elif len(question_text) > MAX_QUESTION_LENGTH:
            errors.append(
                f"{prefix}: question too long ({len(question_text)} chars, "
                f"max {MAX_QUESTION_LENGTH}): {question_text!r}"
            )

        # Validate answer text.
        answer_text = q.get("answer", "")
        if not isinstance(answer_text, str) or not answer_text.strip():
            errors.append(f"{prefix}: 'answer' must be a non-empty string")
        elif len(answer_text) > MAX_ANSWER_LENGTH:
            errors.append(
                f"{prefix}: answer too long ({len(answer_text)} chars, "
                f"max {MAX_ANSWER_LENGTH}): {answer_text!r}"
            )

        # Validate distractors.
        distractors = q.get("distractors", [])
        if not isinstance(distractors, list):
            errors.append(f"{prefix}: 'distractors' must be an array")
        elif len(distractors) != DISTRACTOR_COUNT:
            errors.append(
                f"{prefix}: expected {DISTRACTOR_COUNT} distractors, "
                f"got {len(distractors)}"
            )
        else:
            for j, d in enumerate(distractors):
                if not isinstance(d, str) or not d.strip():
                    errors.append(
                        f"{prefix}: distractor[{j}] must be a non-empty string"
                    )
                elif len(d) > MAX_ANSWER_LENGTH:
                    errors.append(
                        f"{prefix}: distractor[{j}] too long "
                        f"({len(d)} chars, max {MAX_ANSWER_LENGTH}): {d!r}"
                    )

        # Check for duplicate answers.
        all_answers = [answer_text] + list(
            distractors if isinstance(distractors, list) else []
        )
        seen: set[str] = set()
        for a in all_answers:
            lower = a.strip().lower()
            if lower in seen:
                errors.append(f"{prefix}: duplicate answer: {a!r}")
            seen.add(lower)

    return errors


def main() -> int:
    categories_path = QUESTIONS_DIR / "categories.json"
    if not categories_path.exists():
        print(f"ERROR: {categories_path} not found", file=sys.stderr)
        return 1

    categories = json.loads(categories_path.read_text(encoding="utf-8"))
    if not isinstance(categories, list):
        print("ERROR: categories.json root must be an array", file=sys.stderr)
        return 1

    all_errors: list[str] = []
    total_questions = 0

    for cat in categories:
        slug = cat.get("slug", "")
        if not slug:
            all_errors.append("categories.json: entry with empty slug")
            continue
        path = QUESTIONS_DIR / f"{slug}.json"
        if not path.exists():
            all_errors.append(f"categories.json: file not found for slug '{slug}'")
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        total_questions += len(data) if isinstance(data, list) else 0
        all_errors.extend(validate_file(path))

    if all_errors:
        print(
            f"FAILED: {len(all_errors)} error(s) in question data:\n", file=sys.stderr
        )
        for err in all_errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(
        f"OK: {total_questions} questions validated across {len(categories)} categories"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
