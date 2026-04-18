# Fonts

This directory contains the fonts used in Trivia Dash.

## Source Fonts
These are the full, unsubsetted fonts. They are NOT included in the final export.
- `NotoSans.ttf`: Noto Sans Regular (Latin/Greek/Cyrillic).
- `NotoEmoji.ttf`: Noto Color Emoji.

## Subsetted Fonts
These are generated automatically during the build process and are used by the game.
- `NotoSans-subset.ttf`
- `NotoEmoji-subset.ttf`

## How to Update
If you add new questions or change the UI text, the subsetted fonts should be updated. This is handled automatically by the `Makefile` when running `make build` or `make subset-fonts`.

Dependencies:
- `pyftsubset` (from `fonttools` Python package)
- `brotli` (optional, for woff2 support)

To manually trigger subsetting:
```bash
make subset-fonts
```

The script `tools/extract_characters.py` scans all question JSON files and the main scene to find every unique character that needs to be included in the subset.
