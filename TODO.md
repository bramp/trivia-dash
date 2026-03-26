# Trivia Dash — Task List

## Phase 0 — Code Quality Setup

- [ ] Create `pyproject.toml` pinning `gdtoolkit==4.*`
- [ ] Create `.gdlintrc` with Godot-standard lint rules
- [ ] Create `.gdformatrc` (tab indentation, max line length)
- [ ] Create `.pre-commit-config.yaml` with gdformat + gdlint hooks
- [ ] Run `pre-commit install` to activate hooks
- [ ] Install GUT addon into `addons/gut/`
- [ ] Create `test/` directory for GUT test scripts
- [ ] Create `.github/workflows/ci.yml` (lint job + test job)
- [ ] Verify CI pipeline runs green on empty project

## Phase 1 — Project Setup

- [ ] Configure `project.godot` (window size, stretch mode `canvas_items`, aspect `keep_height`)
- [ ] Import Noto Sans font, create global `Theme` resource
- [ ] Define colour constants (background `#2C3E50`, button Red/Green/Blue/Yellow, highlights)
- [ ] Create `main.tscn` with root `Control` node

## Phase 2 — Title Screen

- [ ] Build Title screen UI (title label, Play button, high score label)
- [ ] Add entrance animations (title slides in, button fades up)
- [ ] Wire Play button → transition to Game screen

## Phase 3 — Question Data

- [ ] Create `data/questions.json` with ~10 test questions
- [ ] Write `question_manager.gd` — load JSON, shuffle, serve without repeats, remap correct index
- [ ] Write GUT tests for question_manager:
  - [ ] Loads all questions from JSON
  - [ ] Shuffled answers remap correct index properly
  - [ ] No repeat questions until pool exhausted
  - [ ] Handles empty/malformed JSON gracefully

## Phase 4 — Game Screen Core

- [ ] Build Game screen UI (question label, 4 coloured answer buttons in `VBoxContainer`, timer bar, score label)
- [ ] Style buttons: Red (`#E74C3C`), Green (`#2ECC71`), Blue (`#3498DB`), Yellow (`#F1C40F`) with white text
- [ ] Write `main.gd` game state machine (TITLE → PLAYING → GAME_OVER)
- [ ] Implement 30-second countdown timer with `Timer` node + progress bar tween
- [ ] Wire answer buttons: check correct/incorrect, update score
- [ ] Implement time-based scoring (`base_points=100 + time_bonus=floor(remaining × 50)`)
- [ ] Track per-question elapsed time for score calculation
- [ ] Add keyboard input `1`/`2`/`3`/`4` via `_unhandled_input()`, active only in PLAYING state
- [ ] Handle game-over conditions (wrong answer or timer expires)
- [ ] Write GUT tests for scoring:
  - [ ] `base_points` = 100 for any correct answer
  - [ ] `time_bonus` scales with remaining question time
  - [ ] Score = 0 on immediate wrong answer
  - [ ] Keyboard input 1/2/3/4 triggers correct button

## Phase 5 — Animations

- [ ] Question text entrance animation (slide down + fade in)
- [ ] Answer button staggered entrance (scale + fade, ease-out-back)
- [ ] Correct answer feedback (brighten + scale pulse)
- [ ] Wrong answer feedback (flash + shake)
- [ ] Question-to-question transition (slide out left, next in right)
- [ ] Timer bar colour gradient (green → yellow → red)
- [ ] Score pop animation on increment

## Phase 6 — Game Over Screen

- [ ] Build Game Over UI (final score, high score, Play Again button, Main Menu button)
- [ ] Entrance animations for Game Over elements
- [ ] Wire buttons to restart game or return to title

## Phase 7 — Persistence

- [ ] Create `GameData` autoload singleton
- [ ] Save/load high score to `user://save.json`
- [ ] Display high score on Title and Game Over screens
- [ ] Write GUT tests for persistence:
  - [ ] High score persists across save/load cycle
  - [ ] Handles missing save file gracefully (first run)

## Phase 8 — Polish

- [ ] Screen transition animations (fade/slide between states)
- [ ] Sound effects (correct ding, wrong buzz, timer tick, button tap) — optional
- [ ] Focus/hover states for keyboard/gamepad navigation
- [ ] Run `gdformat` on all scripts, fix formatting
- [ ] Run `gdlint` on all scripts, resolve warnings
- [ ] Test responsive layout at 720×1280, 1920×1080, and in-browser
- [ ] Ensure CI is green

## Phase 9 — Export & Deploy

- [ ] Configure Android export preset, test on device/emulator
- [ ] Configure iOS export preset, test on device/simulator
- [ ] Configure HTML5 export preset, test in browser
- [ ] Configure Desktop export presets (macOS, Windows, Linux)
- [ ] Final cross-platform QA pass

## Stretch Goals

- [ ] Time bonus: +1–2s added back to clock for fast answers
- [ ] Category selection before starting
- [ ] Difficulty scaling (harder questions as streak grows)
- [ ] Leaderboard (local or online)
- [ ] Streak particle effects
