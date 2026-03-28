extends GutTest


func test_placeholder():
	# Placeholder test to verify GUT is working.
	assert_true(true, "GUT is running")


func test_all_scripts_compile() -> void:
	# Validate that all project scripts compile without type or parse errors.
	# This catches issues like := type inference failures in scripts not
	# otherwise loaded by tests (e.g. main.gd).
	var script_paths := [
		"res://scripts/main.gd",
		"res://scripts/game_data.gd",
		"res://scripts/question_manager.gd",
		"res://scripts/build_info.gd",
		"res://scripts/sfx_manager.gd",
	]
	for path: String in script_paths:
		var script: GDScript = load(path)
		assert_not_null(script, "%s should compile without errors" % path)
