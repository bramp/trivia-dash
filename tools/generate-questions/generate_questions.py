#!/usr/bin/env python3
"""Generate trivia questions using Google Gemini and save to data/questions.json.

Usage:
    python3 tools/generate-questions/generate_questions.py --list
    python3 tools/generate-questions/generate_questions.py --categories 1,3,5
    python3 tools/generate-questions/generate_questions.py --categories 1-5
    python3 tools/generate-questions/generate_questions.py --categories emoji,lyrics
    python3 tools/generate-questions/generate_questions.py --categories all

Authentication (pick one):
    1. Create a .env file in the project root with your API key:
           echo 'GEMINI_API_KEY=your-key-here' > .env
       (The .env file is git-ignored and will not be committed.)
    2. Export the environment variable directly:
           export GEMINI_API_KEY=your-key-here
    3. Use Application Default Credentials:
           gcloud auth application-default login

Requirements:
    pip install google-genai json5
"""

import argparse
import json
import os
import random
import re
import sys
import time
from pathlib import Path

try:
    import json5
except ImportError:
    print("Error: json5 is required. Run 'pip install json5'")
    sys.exit(1)

try:
    from google import genai
except ImportError:
    genai = None

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
PROMPT_FILE = SCRIPT_DIR / "prompt.txt"
CATEGORIES_FILE = SCRIPT_DIR / "categories.json"
OUTPUT_FILE = PROJECT_ROOT / "data" / "questions.json"
ENV_FILE = PROJECT_ROOT / ".env"


def _load_env_file() -> None:
    """Load KEY=VALUE pairs from .env into os.environ (if the file exists)."""
    if not ENV_FILE.exists():
        return
    for line in ENV_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, sep, value = line.partition("=")
        if sep:
            os.environ.setdefault(key.strip(), value.strip())


DEFAULT_COUNT = 20
DEFAULT_MODEL = "gemini-3.1-pro-preview"


def load_categories() -> list[dict]:
    """Load category definitions from categories.json."""
    if not CATEGORIES_FILE.exists():
        print(f"Error: Categories file not found at {CATEGORIES_FILE}")
        sys.exit(1)
    return json5.loads(CATEGORIES_FILE.read_text())


def list_categories(categories: list[dict]) -> None:
    """Print available categories with their index and description."""
    print("\nAvailable categories:\n")
    for i, cat in enumerate(categories, 1):
        print(f"  {i:2d}. {cat['title']}  [{cat['slug']}]")
        print(f"      {cat['description']}")
    print()


def select_categories(all_categories: list[dict], selection: str | None) -> list[dict]:
    """Parse a category selection string and return matching categories.

    Selection can be:
      - None or "all" -> all categories
      - Comma-separated indices (e.g. "1,3,5")
      - A range (e.g. "1-5")
      - Comma-separated partial title matches (e.g. "emoji,lyrics")
    """
    if not selection or selection.strip().lower() == "all":
        return all_categories

    # Try parsing as indices / ranges first.
    parts = [p.strip() for p in selection.split(",")]
    indices: list[int] = []
    all_numeric = True
    for part in parts:
        if re.fullmatch(r"\d+", part):
            indices.append(int(part))
        elif m := re.fullmatch(r"(\d+)-(\d+)", part):
            start, end = int(m.group(1)), int(m.group(2))
            indices.extend(range(start, end + 1))
        else:
            all_numeric = False
            break

    if all_numeric and indices:
        selected = []
        for idx in indices:
            if 1 <= idx <= len(all_categories):
                selected.append(all_categories[idx - 1])
            else:
                print(f"Warning: index {idx} out of range (1-{len(all_categories)})")
        if not selected:
            print("Error: no valid categories selected.")
            sys.exit(1)
        return selected

    # Otherwise treat as slug or partial title matches.
    selected = []
    for part in parts:
        needle = part.strip().lower()
        # Exact slug match first, then partial title match.
        matches = [c for c in all_categories if c["slug"] == needle]
        if not matches:
            matches = [c for c in all_categories if needle in c["title"].lower()]
        if not matches:
            matches = [c for c in all_categories if needle in c["slug"]]
        if not matches:
            print(f"Warning: no category matching '{part}'")
        selected.extend(matches)

    # Deduplicate while preserving order.
    seen: set[str] = set()
    unique = []
    for c in selected:
        if c["title"] not in seen:
            seen.add(c["title"])
            unique.append(c)

    if not unique:
        print("Error: no valid categories selected.")
        sys.exit(1)
    return unique


def load_prompt_template() -> str:
    if not PROMPT_FILE.exists():
        print(f"Error: Prompt template not found at {PROMPT_FILE}")
        sys.exit(1)
    return PROMPT_FILE.read_text()


def build_prompt(template: str, category: dict, count: int) -> str:
    example_json = json.dumps(category["example"], indent=2, ensure_ascii=False)
    return template.format(
        topic=category["title"],
        description=category["description"],
        example=example_json,
        count=count,
    )


def extract_json(text: str) -> list:
    """Extract a JSON array of questions from the LLM response."""
    # Strip markdown code fences if present.
    cleaned = re.sub(r"^```(?:json)?\s*\n?", "", text.strip())
    cleaned = re.sub(r"\n?```\s*$", "", cleaned)
    data = json5.loads(cleaned)

    # Handle both bare-array and wrapper-object formats.
    if isinstance(data, dict):
        return data.get("questions", [])
    return data


def convert_to_game_format(q: dict) -> dict:
    """Convert from the LLM's rich format to the game's format."""
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
    client: genai.Client, model: str, template: str, category: dict, count: int
) -> list:
    prompt = build_prompt(template, category, count)

    print(f"  Requesting {count} questions...")
    response = client.models.generate_content(model=model, contents=prompt)

    raw = extract_json(response.text)
    print(f"  Received {len(raw)} questions")

    questions = []
    for q in raw:
        if "question" not in q or "answer" not in q or "distractors" not in q:
            print(f"  Skipping malformed question: {q.get('question', '???')}")
            continue
        if len(q["distractors"]) < 3:
            print(f"  Skipping (< 3 distractors): {q['question']}")
            continue
        questions.append(convert_to_game_format(q))

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


def load_existing(path: Path) -> dict[str, list]:
    """Load existing questions.json and return a {category: [questions]} dict."""
    if not path.exists():
        return {}
    data = json5.loads(path.read_text())
    result = {}
    for cat in data.get("categories", []):
        result[cat["name"]] = cat["questions"]
    return result


def build_output(categories_dict: dict[str, list]) -> dict:
    """Build the output JSON structure from {category: [questions]} dict."""
    categories = []
    for name in sorted(categories_dict):
        questions = deduplicate(categories_dict[name])
        categories.append({"name": name, "questions": questions})
    total = sum(len(c["questions"]) for c in categories)
    return {"categories": categories, "total_questions": total}


def main():
    parser = argparse.ArgumentParser(
        description="Generate trivia questions with Gemini",
    )
    parser.add_argument(
        "--count",
        type=int,
        default=DEFAULT_COUNT,
        help=f"Questions per category (default: {DEFAULT_COUNT})",
    )
    parser.add_argument(
        "--model",
        type=str,
        default=DEFAULT_MODEL,
        help=f"Gemini model name (default: {DEFAULT_MODEL})",
    )
    parser.add_argument(
        "--categories",
        type=str,
        default=None,
        help=(
            "Which categories to generate. Use 'all' for all, "
            "comma-separated indices (e.g. '1,3,5'), a range (e.g. '1-5'), "
            "slugs (e.g. 'emoji-cryptograms,literal-lyrics'), "
            "or partial title matches (e.g. 'emoji,lyrics'). "
            "Use --list to see available categories."
        ),
    )
    parser.add_argument(
        "--list",
        action="store_true",
        dest="list_categories",
        help="List available categories and exit",
    )
    parser.add_argument(
        "--append",
        action="store_true",
        help="Append to existing questions instead of overwriting",
    )
    args = parser.parse_args()

    all_categories = load_categories()

    if args.list_categories:
        list_categories(all_categories)
        sys.exit(0)

    categories = select_categories(all_categories, args.categories)

    template = load_prompt_template()

    _load_env_file()

    if genai is None:
        print("Missing dependency. Install with: pip install google-genai")
        sys.exit(1)

    api_key = os.environ.get("GEMINI_API_KEY")

    if api_key:
        print("Authenticating with Google AI (using GEMINI_API_KEY)...")
        client = genai.Client(api_key=api_key)
    else:
        print(
            "Authenticating with Google AI (using Application Default Credentials)..."
        )
        print(
            "Tip: You can also set GEMINI_API_KEY in a .env file in the project root."
        )
        client = genai.Client()

    # Load existing questions if appending.
    categories_dict: dict[str, list] = {}
    if args.append:
        categories_dict = load_existing(OUTPUT_FILE)
        total = sum(len(v) for v in categories_dict.values())
        if total:
            print(
                f"Loaded {total} existing questions"
                f" across {len(categories_dict)} categories"
            )

    print(
        f"\nGenerating for {len(categories)} categories: "
        f"{', '.join(c['title'] for c in categories)}"
    )

    for i, category in enumerate(categories):
        name = category["title"]
        print(f"\n[{i + 1}/{len(categories)}] Generating: {name}")
        try:
            questions = generate_for_category(
                client, args.model, template, category, args.count
            )
            # Merge into existing category or create new.
            existing = categories_dict.get(name, [])
            existing.extend(questions)
            categories_dict[name] = existing
            print(
                f"  Added {len(questions)} questions"
                f" ({len(existing)} total in category)"
            )
        except Exception as e:
            print(f"  ERROR generating {name}: {e}")
            continue

        # Rate limit between requests.
        if i < len(categories) - 1:
            time.sleep(2)

    output = build_output(categories_dict)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_FILE.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n")
    n_questions = output["total_questions"]
    n_categories = len(output["categories"])
    print(
        f"\nDone! Wrote {n_questions} questions"
        f" across {n_categories} categories to {OUTPUT_FILE}"
    )


if __name__ == "__main__":
    main()
