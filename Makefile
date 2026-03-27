GD_FILES := $(shell find . -name "*.gd" -not -path "./.godot/*" -not -path "./addons/*")
BUILD_DIR := build

.PHONY: format format-check lint test run build generate-questions

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

## Build Web export (requires export templates installed in Godot)
build:
	@if [ ! -f export_presets.cfg ]; then \
		echo "Error: export_presets.cfg not found. Configure export presets in Godot first."; \
		exit 1; \
	fi
	mkdir -p $(BUILD_DIR)/web
	godot --headless --export-release "Web" $(BUILD_DIR)/web/index.html
	@echo "Export written to $(BUILD_DIR)/web/"

## Generate trivia questions using Gemini (requires gcloud auth)
generate-questions:
	python3 scripts/generate_questions.py
