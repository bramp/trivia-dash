#!/usr/bin/env python3
"""Generate trivia questions using Google Gemini and save to data/questions.json.

Usage:
    python3 tools/generate-questions/generate_questions.py [--count N] [--categories CAT1,CAT2,...]

Authentication:
    Uses Application Default Credentials. Run once:
        gcloud auth application-default login

Requirements:
    pip install google-genai
"""

import argparse
import json
import random
import re
import sys
import time
from pathlib import Path

try:
    from google import genai
except ImportError:
    print("Missing dependency. Install with: pip install google-genai")
    sys.exit(1)

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
PROMPT_FILE = SCRIPT_DIR / "prompt.txt"
OUTPUT_FILE = PROJECT_ROOT / "data" / "questions.json"

DEFAULT_CATEGORIES = [
    "Science",
    "World History",
    "Geography",
    "Pop Culture",
    "Sports",
    "Literature",
    "Music",
    "Movies & TV",
    "Food & Drink",
    "Nature & Animals",
    "Technology",
    "Art",
    "Mythology",
    "Space & Astronomy",
    "Human Body & Health",
]

DEFAULT_COUNT = 20
MODEL = "gemini-2.5-flash"


def load_prompt_template() -> str:
    if not PROMPT_FILE.exists():
        print(f"Error: Prompt template not found at {PROMPT_FILE}")
        sys.exit(1)
    return PROMPT_FILE.read_text()


def build_prompt(template: str, topic: str, count: int) -> str:
    return template.format(topic=topic, count=count)


def extract_json(text: str) -> tuple[str, list]:
    """Extract category and questions from the LLM response.

    Returns (category, questions_list).
    """
    # Strip markdown code fences if present.
    cleaned = re.sub(r"^```(?:json)?\s*\n?", "", text.strip())
    cleaned = re.sub(r"\n?```\s*$", "", cleaned)
    data = json.loads(cleaned)

    # Handle both wrapper-object and bare-array formats.
    if isinstance(data, dict):
        category = data.get("category", "")
        questions = data.get("questions", [])
    else:
        category = ""
        questions = data
    return category, questions


def convert_to_game_format(q: dict, category: str) -> dict:
    """Convert from the LLM's rich format to the game's simple format."""
    answer = q["answer"]
    distractors = q["distractors"][:3]

    # Build answers list: correct answer + 3 distractors, then shuffle.
    answers = [answer] + distractors
    random.shuffle(answers)
    correct_index = answers.index(answer)

    result = {
        "question": q["question"],
        "answers": answers,
        "correct": correct_index,
        "category": category or q.get("category", ""),
        "difficulty": q.get("difficulty", "medium"),
    }

    # Preserve optional metadata for review.
    alt = q.get("alternative_answers", [])
    if alt:
        result["alternative_answers"] = alt
    note = q.get("clarity_note", "")
    if note:
        result["clarity_note"] = note

    return result


def generate_for_category(
    client: genai.Client, template: str, topic: str, count: int
) -> list:
    prompt = build_prompt(template, topic, count)

    print(f"  Requesting {count} questions...")
    response = client.models.generate_content(model=MODEL, contents=prompt)

    category, raw = extract_json(response.text)
    print(f"  Received {len(raw)} questions")

    questions = []
    for q in raw:
        if "question" not in q or "answer" not in q or "distractors" not in q:
            print(f"  Skipping malformed question: {q.get('question', '???')}")
            continue
        if len(q["distractors"]) < 3:
            print(f"  Skipping (< 3 distractors): {q['question']}")
            continue
        questions.append(convert_to_game_format(q, category or topic))

    return questions


def deduplicate(questions: list) -> list:
    """Remove questions with duplicate question text."""
    seen = set()
    unique = []
    for q in questions:
        key = q["question"].strip().lower()
        if key not in seen:
            seen.add(key)
            unique.append(q)
    return unique


def main():
    parser = argparse.ArgumentParser(description="Generate trivia questions with Gemini")
    parser.add_argument(
        "--count",
        type=int,
        default=DEFAULT_COUNT,
        help=f"Questions per category (default: {DEFAULT_COUNT})",
    )
    parser.add_argument(
        "--categories",
        type=str,
        default=None,
        help="Comma-separated list of categories (default: built-in list)",
    )
    parser.add_argument(
        "--append",
        action="store_true",
        help="Append to existing questions instead of overwriting",
    )
    args = parser.parse_args()

    categories = (
        [c.strip() for c in args.categories.split(",")]
        if args.categories
        else DEFAULT_CATEGORIES
    )

    template = load_prompt_template()

    print(f"Authenticating with Google AI (using Application Default Credentials)...")
    client = genai.Client()

    all_questions = []

    # Load existing questions if appending.
    if args.append and OUTPUT_FILE.exists():
        existing = json.loads(OUTPUT_FILE.read_text())
        all_questions.extend(existing)
        print(f"Loaded {len(existing)} existing questions")

    for i, category in enumerate(categories):
        print(f"\n[{i + 1}/{len(categories)}] Generating: {category}")
        try:
            questions = generate_for_category(client, template, category, args.count)
            all_questions.extend(questions)
            print(f"  Added {len(questions)} questions (total: {len(all_questions)})")
        except Exception as e:
            print(f"  ERROR generating {category}: {e}")
            continue

        # Rate limit between requests.
        if i < len(categories) - 1:
            time.sleep(2)

    all_questions = deduplicate(all_questions)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(json.dumps(all_questions, indent=2, ensure_ascii=False) + "\n")
    print(f"\nDone! Wrote {len(all_questions)} questions to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
