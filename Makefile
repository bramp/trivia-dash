GD_FILES := $(shell find . -name "*.gd" -not -path "./.godot/*" -not -path "./addons/*")
BUILD_DIR := build

.PHONY: format format-check lint test run build

## Run the game
run:
	godot --path .

## Format all GDScript files in place
format:
	gdformat $(GD_FILES)

## Check GDScript formatting (fails on diff)
format-check:
	gdformat --check $(GD_FILES)

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

## Build exports (requires export presets in export_presets.cfg)
build: $(BUILD_DIR)
	@if [ ! -f export_presets.cfg ]; then \
		echo "Error: export_presets.cfg not found. Configure export presets in Godot first."; \
		exit 1; \
	fi
	godot --headless --export-release "macOS" $(BUILD_DIR)/trivia-dash-macos.zip 2>&1 || true
	godot --headless --export-release "Windows Desktop" $(BUILD_DIR)/trivia-dash-windows.exe 2>&1 || true
	godot --headless --export-release "Linux" $(BUILD_DIR)/trivia-dash-linux.x86_64 2>&1 || true
	godot --headless --export-release "Web" $(BUILD_DIR)/web/index.html 2>&1 || true
	@echo "Exports written to $(BUILD_DIR)/"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)/web
