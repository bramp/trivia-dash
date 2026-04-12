# Agent Rules

## Commit Workflow

1. **Always run validation before committing**: Run `make format-check && make lint` (and `make test` when GDScript files changed) before every commit. Fix any issues before proceeding.
2. **Ask before committing**: Always show the user what changed (e.g. `git diff --stat`) and ask for explicit confirmation before running `git commit`.
3. **Ask before pushing**: Always ask for explicit confirmation before running `git push`.

## Code Quality

- Format GDScript with `gdformat` and Python with `ruff format`.
- Lint GDScript with `gdlint` and Python with `ruff check`.
- Run tests with `make test`.
- Pre-commit hooks are configured — they run automatically on `git commit`, but do not rely on them as the sole check. Always validate manually first.

## Project Conventions

- **Engine**: Godot 4.6, GDScript, single-scene architecture.
- **Build**: `make build` for Web export, `make run` to launch locally.
- **Tests**: GUT framework in `test/` directory, headless via `make test`.
- **Python tooling**: Located in `tools/`, uses ruff for linting/formatting.
- **Fonts**: Noto Sans + Noto Emoji bundled in `fonts/`, used via theme with FontVariation.

## Styling & Theming

- **Static visual properties go in the theme or scene, not in GDScript.** Font sizes, font colors, stylebox colors, margins, corner radii, and other properties that don't change at runtime must be defined in `theme/default_theme.tres` (via theme type variations) or as `theme_override_*` properties in `scenes/main.tscn`. Never use `add_theme_*_override()` in scripts for values that are constant.
- **Use theme type variations** (e.g. `TitleLabel`, `HudLabel`, `PlayButton`, `AnswerButton`) to group shared static styles. Assign them to nodes via `theme_type_variation` in the `.tscn` file.
- **Per-node style overrides** (e.g. per-button colors) belong as inline `SubResource` styleboxes in the `.tscn` file, not created in code.
- **Reserve GDScript styling for dynamic/runtime changes only**: animations, state-dependent color transitions (e.g. timer bar color lerp), correct/wrong answer highlights, and temporary effects.

## Question Data

- **File format**: Question files use `answer` (string) + `distractors` (array of 3 strings), **not** an `answers` array. See `data/questions/README.md` for full schema.
- **Text length limits**: Questions ≤ 150 chars, answers/distractors ≤ 100 chars. Enforced by `make validate-questions` (runs automatically as part of `make test`).
- **Validation**: Run `make validate-questions` to check all question data for structure, lengths, and duplicates.

## Testing Notes

- **GUT tests run headless** (`--headless`), so UI controls have zero size — font measurement and layout-dependent assertions won't produce meaningful results. Use Python scripts (`tools/`) for data validation instead.
- **Resolution testing**: Use `make run-720p`, `make run-1080p`, `make run-4k`, `make run-phone`, `make run-tablet`, or `make run RES=WxH`. Press **F3** in debug builds to cycle resolutions at runtime.
- **Dev stress test data**: `data/questions/_dev-text-stress.json` has extreme text lengths for manual UI testing. Add its slug to `categories.json` temporarily to use it.

## GDScript Pitfalls

- **gdlint enforces declaration order**: `const` must come before `var` in class scope. Violating this produces `class-definitions-order` errors.
- **`clip_text = true` on Buttons silently hides overflow** — prefer `autowrap_mode` with dynamic font sizing instead.
