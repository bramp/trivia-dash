BUILD_DIR := build
VENV_DIR := .venv
GODOT_SOURCE := ../godot

# Directories to ignore in all searches
EXCLUDE_DIRS := .godot addons third_party $(BUILD_DIR) $(VENV_DIR) android

# Helper to generate find exclude patterns
# usage: $(call find_exclude,path_list)
find_exclude = $(foreach dir,$(1),-not -path "./$(dir)/*")

GD_FILES := $(shell find . -name "*.gd" $(call find_exclude,$(EXCLUDE_DIRS)))
PY_FILES := $(shell find . -name "*.py" $(call find_exclude,$(EXCLUDE_DIRS)))

# Font subsetting variables
QUESTION_FILES := $(wildcard data/questions/*.json)
SCENE_FILES := scenes/main.tscn
CHARS_FILE := fonts/unique_chars.txt
SUBSET_FONTS := fonts/NotoSans-subset.ttf fonts/NotoColorEmoji-subset.ttf

.PHONY: format format-check format-check-gd format-check-py lint test validate-questions run build build-web build-mac build-android build-templates build-templates-web build-templates-mac build-templates-android serve generate-questions venv subset-fonts clean-fonts

## Run the game (optionally at a specific resolution: make run RES=1920x1080)
run:
ifdef RES
	godot --path . --resolution $(RES)
else
	godot --path .
endif

## Run at common screen sizes for testing
run-720p:
	$(MAKE) run RES=1280x720

run-1080p:
	$(MAKE) run RES=1920x1080

run-4k:
	$(MAKE) run RES=3840x2160

run-phone:
	$(MAKE) run RES=390x844

run-tablet:
	$(MAKE) run RES=1024x768

## Serve the web build (requires Python 3)
serve: build
	@python3 tools/serve.py $(BUILD_DIR)/web

## Format all GDScript files in place
format:
	gdformat $(GD_FILES)
	ruff format $(PY_FILES)
	ruff check --fix $(PY_FILES)

## Check GDScript and Python formatting / linting (fails on diff)
format-check: format-check-gd format-check-py

format-check-gd:
	gdformat --check $(GD_FILES)

format-check-py:
	ruff format --check $(PY_FILES)
	ruff check $(PY_FILES)

## Lint all GDScript files
lint:
	gdlint $(GD_FILES)

## Run GUT unit tests (requires Godot in PATH)
test: validate-questions
	godot --headless --script addons/gut/gut_cmdln.gd \
		-gdir=res://test/ \
		-gprefix=test_ \
		-gsuffix=.gd \
		-gexit

## Validate question data (structure, text lengths, duplicates)
validate-questions:
	python3 tools/validate_questions.py

## Generate subsetted fonts based on characters used in questions and UI
subset-fonts: venv $(SUBSET_FONTS)

$(CHARS_FILE): $(QUESTION_FILES) $(SCENE_FILES) tools/extract_characters.py venv
	@mkdir -p fonts
	$(VENV_DIR)/bin/python3 tools/extract_characters.py > $@

fonts/NotoSans-subset.ttf: fonts/NotoSans.ttf $(CHARS_FILE)
	@echo "Subsetting NotoSans..."
	$(VENV_DIR)/bin/pyftsubset $< --text-file=$(CHARS_FILE) --output-file=$@

fonts/NotoColorEmoji-subset.ttf: fonts/NotoColorEmoji.ttf $(CHARS_FILE)
	@echo "Subsetting NotoColorEmoji..."
	# Color emojis require keeping layout features and glyph names for proper rendering
	$(VENV_DIR)/bin/pyftsubset $< --text-file=$(CHARS_FILE) --output-file=$@ --layout-features='*' --glyph-names --legacy-cmap --notdef-outline

## Remove subsetted fonts and character list
clean-fonts:
	rm -f $(SUBSET_FONTS) $(CHARS_FILE)

## Build all exports
build: build-web build-mac build-android

## Build Web export
build-web: subset-fonts
	@if [ ! -f export_presets.cfg ]; then \
		echo "Error: export_presets.cfg not found. Configure export presets in Godot first."; \
		exit 1; \
	fi
	@# Stamp build date/time into build_info.gd
	@sed -i.bak 's/^const BUILD_DATE := .*/const BUILD_DATE := "'"$$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"/' scripts/build_info.gd && rm -f scripts/build_info.gd.bak
	mkdir -p $(BUILD_DIR)/web
	godot --headless --export-release "Web" $(BUILD_DIR)/web/index.html
	@# Reset build_info.gd back to dev
	@sed -i.bak 's/^const BUILD_DATE := .*/const BUILD_DATE := "dev"/' scripts/build_info.gd && rm -f scripts/build_info.gd.bak
	@# Optimize wasm with wasm-opt (from binaryen) if available
	@if command -v wasm-opt >/dev/null 2>&1; then \
		echo "Running wasm-opt..."; \
		wasm-opt $(BUILD_DIR)/web/index.wasm -o $(BUILD_DIR)/web/index.wasm -all -Oz; \
	else \
		echo "Warning: wasm-opt not found, skipping wasm optimization. Install binaryen to enable."; \
	fi
	@echo "Build sizes:"
	@ls -lh $(BUILD_DIR)/web/index.wasm $(BUILD_DIR)/web/index.pck $(BUILD_DIR)/web/index.js
	@echo "Export written to $(BUILD_DIR)/web/"

## Build macOS export
build-mac: subset-fonts
	mkdir -p $(BUILD_DIR)/macos
	godot --headless --export-release "macOS" $(BUILD_DIR)/macos/trivia-dash.zip
	@ls -lh $(BUILD_DIR)/macos/trivia-dash.zip

## Build Android export (requires keystore and SDK setup)
build-android: subset-fonts
	mkdir -p $(BUILD_DIR)/android
	godot --headless --export-release "Android" $(BUILD_DIR)/android/trivia-dash.apk
	@ls -lh $(BUILD_DIR)/android/trivia-dash.apk

## Create/update the Python virtual environment and install all dependencies
venv: $(VENV_DIR)/.installed
	@echo "Virtual environment is set up and dependencies are installed."
	@echo "To activate the virtual environment, run: source $(VENV_DIR)/bin/activate"

$(VENV_DIR)/.installed: pyproject.toml
	python3 -m venv $(VENV_DIR)
	$(VENV_DIR)/bin/pip install --upgrade pip
	$(VENV_DIR)/bin/pip install ".[dev,generate]"
	@touch $@

## Generate trivia questions using Gemini (requires gcloud auth + make venv)
generate-questions: venv
	$(VENV_DIR)/bin/python tools/generate-questions/generate_questions.py

## Build custom Godot export templates for all platforms
build-templates: build-templates-web build-templates-mac build-templates-android

build-templates-web:
	@if [ ! -d $(GODOT_SOURCE) ]; then \
		echo "Error: Godot source not found at $(GODOT_SOURCE)."; \
		exit 1; \
	fi
	cd $(GODOT_SOURCE) && scons platform=web target=template_release profile=$(shell pwd)/tools/build/web_release.py build_profile=$(shell pwd)/tools/build/trivia_dash.build -j$$(sysctl -n hw.logicalcpu)
	@echo "Web templates built in $(GODOT_SOURCE)/bin/"

build-templates-mac:
	@if [ ! -d $(GODOT_SOURCE) ]; then \
		echo "Error: Godot source not found at $(GODOT_SOURCE)."; \
		exit 1; \
	fi
	cd $(GODOT_SOURCE) && scons platform=macos target=template_release profile=$(shell pwd)/tools/build/web_release.py build_profile=$(shell pwd)/tools/build/trivia_dash.build -j$$(sysctl -n hw.logicalcpu)
	@echo "macOS templates built in $(GODOT_SOURCE)/bin/"

build-templates-android:
	@if [ ! -d $(GODOT_SOURCE) ]; then \
		echo "Error: Godot source not found at $(GODOT_SOURCE)."; \
		exit 1; \
	fi
	@if [ -z "$$ANDROID_HOME" ]; then \
		export ANDROID_HOME=~/Library/Android/sdk; \
	fi
	cd $(GODOT_SOURCE) && scons platform=android target=template_release profile=$(shell pwd)/tools/build/web_release.py build_profile=$(shell pwd)/tools/build/trivia_dash.build -j$$(sysctl -n hw.logicalcpu)
	@echo "Android templates built in $(GODOT_SOURCE)/bin/"
