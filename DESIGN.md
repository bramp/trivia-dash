# Trivia Dash — Game Design Document

## Overview

Trivia Dash is a fast-paced multiple-choice trivia game built with Godot 4.6. The player has **30 seconds** to answer as many questions correctly as possible. One wrong answer ends the game immediately. Faster answers earn more points.

**Platforms:** Mobile (Android/iOS), Web (HTML5), Desktop (macOS, Windows, Linux)

## Screens

| Screen      | Elements                                                              |
| ----------- | --------------------------------------------------------------------- |
| **Title**   | Game title, Play button, high score display                           |
| **Game**    | Question text, 4 coloured answer buttons, countdown timer bar, score  |
| **Game Over** | Final score, high score (if beaten), Play Again button, Main Menu button |

## Core Loop

1. Player taps **Play** → timer starts at 30 seconds, first question animates in.
2. Question text and 4 shuffled answer buttons appear with staggered entrance animations.
3. Player taps an answer button or presses **1/2/3/4** on the keyboard:
   - **Correct** → button flashes bright, score increments, current question animates out, next question animates in.
   - **Wrong** → button flashes and shakes, brief pause, transition to Game Over.
4. If the timer reaches **0** → Game Over.

## Scoring

Each correct answer earns points based on speed:

```
score_per_question = base_points + time_bonus
```

| Component      | Formula                                    | Example                        |
| -------------- | ------------------------------------------ | ------------------------------ |
| `base_points`  | `100` (fixed)                              | Always 100                     |
| `time_bonus`   | `floor(question_time_remaining × 50)`      | 2.5s remaining → 125 bonus     |
| **Total**      | `base_points + time_bonus`                 | 100 + 125 = **225 points**     |

- `question_time_remaining` = seconds since the question appeared, capped at the global remaining time.
- A question answered in 0.5s earns ~225 pts; one answered in 3s earns ~150 pts.
- High score is persisted locally.

## Answer Buttons

Four buttons with **fixed colours per position** — answers shuffle into them, colours don't move:

| Position | Colour     | Hex         | Keyboard |
| -------- | ---------- | ----------- | -------- |
| 1        | **Red**    | `#E74C3C`   | `1`      |
| 2        | **Green**  | `#2ECC71`   | `2`      |
| 3        | **Blue**   | `#3498DB`   | `3`      |
| 4        | **Yellow** | `#F1C40F`   | `4`      |

- White text on each button with the answer text.
- Rounded rectangle `StyleBoxFlat`, bold font.
- Touch-friendly size (minimum 48×48 dp).

## Input

- **Touch / Click** on answer buttons (mobile, web, desktop).
- **Keyboard** shortcuts `1`, `2`, `3`, `4` via `_unhandled_input()`, active only during the PLAYING state.

## Animation Spec (Tweens)

All animations use Godot's built-in `Tween` system — no `AnimationPlayer` needed.

| Element                  | Animation                                                    | Duration |
| ------------------------ | ------------------------------------------------------------ | -------- |
| Question text in         | Slide down from above + fade in (ease-out)                   | 0.3s     |
| Answer buttons in        | Staggered scale 0→1 + fade in (ease-out-back, 0.05s stagger) | 0.2s each |
| Correct answer tap       | Brighten + scale pulse 1.0→1.1→1.0                          | 0.15s    |
| Correct transition out   | All buttons + question slide out left + fade                 | 0.25s    |
| Wrong answer tap         | Flash + horizontal shake ±8px, 3 cycles                     | 0.3s     |
| Wrong → Game Over        | Brief pause before transition                                | 0.5s     |
| Timer bar                | Smooth width tween; colour green→yellow→red                  | 30s      |
| Score counter             | Number pop / scale-up on increment                           | 0.15s    |
| Screen transitions       | Fade or slide between Title ↔ Game ↔ Game Over               | 0.4s     |

## Question Data Format

Questions are stored in `res://data/questions.json`:

```json
[
  {
    "question": "What is the capital of France?",
    "answers": ["Paris", "London", "Berlin", "Madrid"],
    "correct": 0
  }
]
```

- `answers` array is **shuffled at runtime** and the `correct` index is remapped.
- Ship with ~10 test questions. The full question bank is provided separately.

## Architecture

### Single-Scene Design

One scene (`main.tscn`) with child containers for each screen state, toggled via visibility and tweens.

### Scripts

| Script                 | Responsibility                                                    |
| ---------------------- | ----------------------------------------------------------------- |
| `main.gd`             | Game state machine (TITLE → PLAYING → GAME_OVER), transitions, keyboard input |
| `question_manager.gd` | Load JSON, shuffle questions, serve one at a time without repeats |
| `hud.gd`              | Timer display, score display, timer bar colour gradient           |
| `answer_button.gd`    | Button tap handling, correct/wrong animations                     |

### Autoloads

| Autoload   | Responsibility                                     |
| ---------- | -------------------------------------------------- |
| `GameData` | High score persistence (`user://save.json`), scoring constants |

## Platform & Responsive UI

- **Control nodes** with anchor presets (full-rect, center) so layout adapts to any aspect ratio.
- **Stretch mode:** `canvas_items`, **Aspect:** `keep_height`.
- **Mobile:** portrait orientation, touch input.
- **Desktop / Web:** fixed-ratio window, keyboard + mouse.
- Test at: 720×1280 (portrait mobile), 1920×1080 (landscape desktop), in-browser.

## Visual Style

- **Dark background:** `#2C3E50` — makes coloured buttons pop.
- **Bold coloured buttons:** Red, Green, Blue, Yellow as specified above.
- **Font:** Clean sans-serif (Noto Sans, bundled as `.ttf` in a Theme resource).
- **Flat design** — rounded rectangles, no sprite art, all UI-driven.

## Code Quality

| Tool                        | Purpose                                     |
| --------------------------- | ------------------------------------------- |
| **gdtoolkit** (`gdlint`)   | GDScript linting (Godot style conventions)  |
| **gdtoolkit** (`gdformat`) | GDScript formatting (tab indentation)       |
| **GUT**                     | Godot Unit Test addon for unit tests        |
| **pre-commit**              | Runs gdformat + gdlint on staged `.gd` files |
| **GitHub Actions**          | CI: lint job + test job (Godot headless)    |

### Config Files

- `.gdlintrc` — lint rules
- `.gdformatrc` — format settings
- `.pre-commit-config.yaml` — pre-commit hooks
- `.github/workflows/ci.yml` — CI pipeline
- `pyproject.toml` — pins gdtoolkit version

### Test Coverage

- `question_manager.gd` — loading, shuffling, correct index remapping, no repeats
- `GameData` — scoring formula, high score save/load
- Scoring edge cases (answer at 0s remaining, instant answer)

## Stretch Goals

- Time bonus: +1–2 seconds added back to the clock for fast answers.
- Category selection before starting a round.
- Difficulty scaling: questions get harder as streak grows.
- Leaderboard (local or online).
- Particle effects on correct-answer streaks.
