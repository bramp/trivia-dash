# Godot Build Minification TODO

## Baseline (v4.6.2.stable.official)
### Web
- **index.wasm**: 33MB
- **index.pck**: 2.8MB
- **index.js**: 308KB
- **Total**: ~36.1MB

### macOS
- **trivia-dash.zip**: 63MB

### Android (Debug)
- **trivia-dash-debug.apk**: 30MB

## Optimization Steps

### 1. Engine Compilation Configuration (.build file)
- [x] Create a `trivia_dash.build` file using the Godot editor's "Engine Compilation Configuration" tool to exclude unused classes.
- [x] Export using this build configuration.
- [x] Record impact:
  - **Web Total**: ~22.1MB (No further reduction from Step 2, but provides safety).
  - **macOS Total**:
  - **Android Total**:

### 2. Custom Export Templates (Custom Build)
- [x] Clone/Setup Godot source code.
- [x] Create `custom.py` (stored as `tools/build/web_release.py`)
- [x] Compile release templates for Web.
- [/] Compile release templates for macOS and Android. (In progress)
- [x] Record impact:
  - **Web Total**: ~19.4MB (index.wasm: 19MB, index.pck: 329KB, index.js: 314KB) - **Impact: -16.7MB**
  - **macOS Total**: ~21MB (trivia-dash.zip) - **Impact: -42MB**
  - **Android Total**: (Pending custom build)

### 3. PCK Optimization
- [x] Review `export_presets.cfg` for unnecessary file inclusions.
- [x] Tested `selected_scenes` filter.
- [x] Subset fonts using `pyftsubset`. (Reduced fonts from 3.9MB to ~65KB).
- [ ] Compress texture assets if applicable. (Icons are already small).
- [x] Record impact:
  - **PCK Size**: 329KB (Reduced from 2.8MB baseline).
