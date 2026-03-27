GD_FILES := $(shell find . -name "*.gd" -not -path "./.godot/*" -not -path "./addons/*")
BUILD_DIR := build
VENV_DIR := .venv

PY_FILES := $(shell find . -name "*.py" -not -path "./.godot/*" -not -path "./$(VENV_DIR)/*")

.PHONY: format format-check format-check-gd format-check-py lint test run build serve generate-questions venv

## Run the game
run:
	godot --path .

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
test:
	godot --headless --script addons/gut/gut_cmdln.gd \
		-gdir=res://test/ \
		-gprefix=test_ \
		-gsuffix=.gd \
		-gexit

## Build Web export (requires export templates installed in Godot)
build:
	@if [ ! -f export_presets.cfg ]; then \
		echo "Error: export_presets.cfg not found. Configure export presets in Godot first."; \
		exit 1; \
	fi
	@# Stamp build date into build_info.gd
	@sed -i '' 's/^const BUILD_DATE := .*/const BUILD_DATE := "'"$$(date -u +%Y-%m-%d)"'"/' scripts/build_info.gd
	mkdir -p $(BUILD_DIR)/web
	godot --headless --export-release "Web" $(BUILD_DIR)/web/index.html
	@# Reset build_info.gd back to dev
	@sed -i '' 's/^const BUILD_DATE := .*/const BUILD_DATE := "dev"/' scripts/build_info.gd
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
