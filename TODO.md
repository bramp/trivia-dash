# Trivia Dash — Task List

## Phase 0 — Code Quality Setup

- [x] Create `pyproject.toml` pinning `gdtoolkit==4.*`
- [x] Create `.gdlintrc` with Godot-standard lint rules
- [x] Create `.gdformatrc` (tab indentation, max line length)
- [x] Create `.pre-commit-config.yaml` with gdformat + gdlint hooks
- [x] Run `pre-commit install` to activate hooks
- [x] Install GUT addon into `addons/gut/`
- [x] Create `test/` directory for GUT test scripts
- [x] Create `.github/workflows/ci.yml` (lint job + test job)
- [x] Verify CI pipeline runs green on empty project

## Phase 1 — Project Setup

- [x] Configure `project.godot` (window size, stretch mode `canvas_items`, aspect `keep_height`)
- [x] Define colour constants (background `#2C3E50`, button Red/Green/Blue/Yellow, highlights)
- [x] Create `main.tscn` with root `Control` node

## Phase 2 — Title Screen

- [x] Build Title screen UI (title label, Play button, high score label)
- [x] Add entrance animations (title slides in, button fades up)
- [x] Wire Play button → transition to Game screen

## Phase 3 — Question Data

- [x] Create `data/questions.json` with ~10 test questions
- [x] Write `question_manager.gd` — load JSON, shuffle, serve without repeats, remap correct index
- [x] Write GUT tests for question_manager:
  - [x] Loads all questions from JSON
  - [x] Shuffled answers remap correct index properly
  - [x] No repeat questions until pool exhausted
  - [x] Handles empty/malformed JSON gracefully

## Phase 4 — Game Screen Core

- [x] Build Game screen UI (question label, 4 coloured answer buttons in 2×2 `GridContainer`, timer bar, score label)
- [x] Style buttons: Red (`#E74C3C`), Green (`#2ECC71`), Blue (`#3498DB`), Yellow (`#F1C40F`) with white text
- [x] Write `main.gd` game state machine (TITLE → PLAYING → GAME_OVER)
- [x] Implement 30-second countdown timer with `Timer` node + progress bar tween
- [x] Wire answer buttons: check correct/incorrect, update score
- [x] Implement time-based scoring (`base_points=100 + time_bonus=floor(remaining × 50)`)
- [x] Track per-question elapsed time for score calculation
- [x] Add keyboard input `1`/`2`/`3`/`4` via `_unhandled_input()`, active only in PLAYING state
- [x] Handle game-over conditions (wrong answer or timer expires)
- [x] Write GUT tests for scoring:
  - [x] `base_points` = 100 for any correct answer
  - [x] `time_bonus` scales with remaining question time
  - [x] Score = 0 on immediate wrong answer

## Phase 5 — Animations

- [x] Question text entrance animation (slide down + fade in)
- [x] Answer button staggered entrance (scale + fade, ease-out-back)
- [x] Correct answer feedback (brighten + scale pulse + emoji burst + floating score)
- [x] Wrong answer feedback (flash + shake)
- [x] Question-to-question transition (slide out left, next in right)
- [x] Timer bar colour gradient (green → yellow → red)
- [x] Score pop animation on increment

## Phase 6 — Game Over Screen

- [x] Build Game Over UI (final score, high score, Play Again button, Main Menu button)
- [x] Entrance animations for Game Over elements
- [x] Wire buttons to restart game or return to title

## Phase 7 — Persistence

- [x] Create `GameData` autoload singleton
- [x] Save/load high score to `user://save.json`
- [x] Display high score on Title and Game Over screens
- [x] Write GUT tests for persistence:
  - [x] High score persists across save/load cycle
  - [x] Handles missing save file gracefully (first run)

## Phase 8 — Polish

- [x] Screen padding (MarginContainer wrappers on all screens)
- [x] Larger font sizes across all screens
- [x] 2×2 answer button grid layout
- [x] Sound effects (correct ding, wrong buzz, timer tick, button tap, game over, new high score)
- [x] Fun correct-answer celebration animation (emoji burst + floating score)
- [ ] Focus/hover states for keyboard/gamepad navigation
- [ ] Run `gdformat` on all scripts, fix formatting
- [ ] Run `gdlint` on all scripts, resolve warnings
- [ ] Test responsive layout at 720×1280, 1920×1080, and in-browser
- [ ] Ensure CI is green
- [ ] Update `README.md` with project description, screenshots, and setup instructions

## Phase 9 — Export & Deploy

- [ ] Configure Android export preset, test on device/emulator
- [ ] Configure iOS export preset, test on device/simulator
- [ ] Configure HTML5 export preset, test in browser
- [ ] Configure Desktop export presets (macOS, Windows, Linux)
- [ ] Final cross-platform QA pass

## Stretch Goals

- [ ] Time bonus: +1–2s added back to clock for fast answers
- [ ] Image support for questions (display an image as part of the question)
- [ ] Image support for answers (image-based answer choices)
- [ ] Difficulty levels (easy/medium/hard question pools)
- [ ] Category selection before starting a round
- [ ] Leaderboard / online high scores
- [ ] Category selection before starting
- [ ] Difficulty scaling (harder questions as streak grows)
- [ ] Leaderboard (local or online)
- [ ] Streak particle effects
