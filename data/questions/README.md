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
