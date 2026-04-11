# Question Data

This directory holds generated trivia question files used by the game at runtime.

## Setup

Run the question generator to populate this directory:

```bash
python3 tools/generate-questions/generate_questions.py --categories all
```

This creates one JSON file per category (e.g. `the-i-should-know-this-vault.json`)
and a `categories.json` manifest that the game reads to discover available categories.

See `tools/generate-questions/` for full usage (e.g. `--list`, `--count`, `--model`).

## Files

- **`categories.json`** — Manifest listing available categories (tracked in git).
- **`<slug>.json`** — Generated question files (gitignored, re-generated on demand).

## File Formats

### `categories.json`

A JSON array of category objects. The game reads this at startup to discover which question files to load.

```json
[
  {
    "title": "The 'I Should Know This' Vault",
    "slug": "the-i-should-know-this-vault"
  }
]
```

| Field   | Type   | Description                                                        |
| ------- | ------ | ------------------------------------------------------------------ |
| `title` | string | Human-readable category name (not currently shown in-game).        |
| `slug`  | string | Filename stem — the game loads `<slug>.json` from this directory.  |

### `<slug>.json` (question files)

Each category file is a JSON array of question objects:

```json
[
  {
    "question": "How many days are in a standard leap year?",
    "answer": "366",
    "alternative_answers": ["366 days"],
    "distractors": ["365", "364", "367"],
    "difficulty": "easy",
    "source": "NASA",
    "clarity_note": "A leap year contains one extra day, February 29th.",
    "model": "gemini-3.1-pro-preview",
    "generated_at": "2026-03-27T23:02:48.658278+00:00"
  }
]
```

| Field                 | Type     | Used in-game | Description                                                                 |
| --------------------- | -------- | ------------ | --------------------------------------------------------------------------- |
| `question`            | string   | **Yes**      | The question text displayed to the player.                                  |
| `answer`              | string   | **Yes**      | The correct answer. Shown as one of the four buttons.                       |
| `distractors`         | string[] | **Yes**      | Three wrong answers. Combined with `answer` and shuffled into four buttons. |
| `alternative_answers` | string[] | No           | Alternate phrasings of the correct answer (for generation QA only).         |
| `difficulty`          | string   | No           | Difficulty tag (`easy`, `medium`, `hard`) — reserved for future use.        |
| `source`              | string   | No           | Attribution/source for the fact.                                            |
| `clarity_note`        | string   | No           | Explanation of the answer (for generation QA only).                         |
| `model`               | string   | No           | LLM model that generated the question.                                     |
| `generated_at`        | string   | No           | ISO 8601 timestamp of generation.                                           |

## How Questions Are Used

At startup, `QuestionManager` (`scripts/question_manager.gd`) loads `categories.json`, then reads each `<slug>.json` file listed in it. All questions are pooled together, shuffled, and served one at a time during gameplay.

For each question, the game:

1. Takes the `answer` and three `distractors` (4 strings total).
2. Shuffles them randomly into the four coloured answer buttons.
3. Tracks which button index holds the correct answer.

Fields like `difficulty`, `source`, `clarity_note`, `model`, and `generated_at` are metadata — they are not read by the game engine.
