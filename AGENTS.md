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
