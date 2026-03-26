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

Install the formatting and linting tools:

```bash
pip install "gdtoolkit>=4,<5"
```

Install pre-commit hooks:

```bash
pip install pre-commit
pre-commit install
```

### Make Targets

| Command | Description |
|---------|-------------|
| `make format` | Format all GDScript files in place |
| `make format-check` | Check formatting (fails on diff) |
| `make lint` | Lint all GDScript files |
| `make test` | Run GUT unit tests (requires Godot in PATH) |

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