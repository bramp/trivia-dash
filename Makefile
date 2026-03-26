GD_FILES := $(shell find . -name "*.gd" -not -path "./.godot/*" -not -path "./addons/*")

.PHONY: format format-check lint test

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
