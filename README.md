# Trivia Dash

A fast-paced multiple-choice trivia game built with **Godot 4.6** and GDScript.

Answer questions before the 30-second timer runs out — but one wrong answer ends the game. Faster answers earn more points.

## Features

- 30-second countdown with time-based scoring
- 4 coloured answer buttons in a 2×2 grid (Red / Green / Blue / Yellow)
- Keyboard shortcuts (1 / 2 / 3 / 4)
- Programmatic sound effects (correct, wrong, tick, tap, game over, new high score)
- Celebration animation on correct answers (emoji burst + floating score)
- Tween-based UI animations throughout
- High score persistence (`user://save.json`)

## Requirements

- [Godot 4.6+](https://godotengine.org/download)
- Python 3.10+ (for linting/formatting tools)

## Getting Started

```bash
# Clone the repo
git clone https://github.com/bramp/trivia-dash.git
cd trivia-dash

# Open in Godot
godot project.godot

# Or run directly from the command line
godot --path .
```

## Development

Set up the Python virtual environment (installs formatters, linters, and question generator dependencies):

```bash
make venv
```

This creates a `.venv/` directory and installs all Python dependencies from `pyproject.toml`. Re-run it any time `pyproject.toml` changes.

Install pre-commit hooks:

```bash
.venv/bin/pre-commit install
```

### Make Targets

| Command | Description |
|---------|-------------|
| `make venv` | Create/update the Python virtual environment |
| `make run` | Launch the game |
| `make format` | Format all GDScript files in place |
| `make format-check` | Check formatting (fails on diff) |
| `make lint` | Lint all GDScript files |
| `make test` | Run GUT unit tests (requires Godot in PATH) |
| `make build` | Export release builds (requires export presets) |
| `make generate-questions` | Generate trivia questions via Gemini (requires `gcloud auth application-default login`) |

### Project Structure

```
scripts/
  main.gd              # Game controller (state machine, UI, animations)
  game_data.gd          # Global constants and high score persistence
  question_manager.gd   # Load, shuffle, and serve trivia questions
  sfx_manager.gd        # Programmatic sound effects
scenes/
  main.tscn             # Single scene with all three screens
data/
  questions.json        # Trivia question pool
test/
  test_game_data.gd     # Scoring and persistence tests
  test_question_manager.gd  # Question loading and shuffling tests
```

## License

See [LICENSE](LICENSE) for details.