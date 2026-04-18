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
- [ ] Create a `trivia_dash.build` file using the Godot editor's "Engine Compilation Configuration" tool to exclude unused classes.
- [ ] Export using this build configuration.
- [ ] Record impact:
  - **Web Total**:
  - **macOS Total**:
  - **Android Total**:

### 2. Custom Export Templates (Custom Build)
- [x] Clone/Setup Godot source code.
- [x] Create `custom.py` (stored as `tools/build/web_release.py`)
- [x] Compile release templates for Web.
- [ ] Record impact:
  - **Web Total**: ~22.1MB (index.wasm: 19MB, index.pck: 2.8MB) - **Impact: -14MB**
  - **macOS Total**:
  - **Android Total**:

### 3. PCK Optimization
- [ ] Review `export_presets.cfg` for unnecessary file inclusions (e.g. `addons/gut` in macOS build).
- [ ] Compress texture assets if applicable.
- [ ] Record impact:
  - **PCK Size**:
