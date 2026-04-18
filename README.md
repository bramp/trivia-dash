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
| `make run` | Launch the game locally |
| `make test` | Run all tests (questions + unit tests) |
| `make format` | Format all scripts (GDScript + Python) |
| `make lint` | Lint all scripts |
| `make build-web` | Export optimized Web build (WASM) |
| `make build-mac` | Export macOS application |
| `make build-android` | Export Android APK (signed) |
| `make build-templates` | Build custom Godot engine templates (requires source) |
| `make generate-questions` | Generate trivia questions via Gemini |

### Build Minification

This project uses custom Godot engine builds to minimize the export size (especially for Web).
- **Web Build**: Reduced from 33MB to ~19MB WASM using custom compilation flags and a minimal engine profile.
- **Tools**: See `tools/build/` for the SCons profiles and class-level exclusion configurations.

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