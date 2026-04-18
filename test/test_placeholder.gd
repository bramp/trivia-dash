extends GutTest


func test_placeholder():
	# Placeholder test to verify GUT is working.
	assert_true(true, "GUT is running")


func test_all_scripts_compile() -> void:
	# Validate that all project scripts compile without type or parse errors.
	var script_paths := _get_all_gd_scripts("res://")
	for path: String in script_paths:
		var script: GDScript = load(path)
		assert_not_null(script, "%s should load" % path)
		if script:
			assert_true(script.can_instantiate(), "%s should be instantiable (i.e. compile without errors)" % path)


func _get_all_gd_scripts(path: String) -> Array[String]:
	var paths: Array[String] = []
	var dirs: Array[String] = [path]
	var exclude_dirs := ["addons", "third_party", "android", "build", ".godot"]

	while not dirs.is_empty():
		var current_dir: String = dirs.pop_back()
		var dir := DirAccess.open(current_dir)
		if dir:
			dir.list_dir_begin()
			var file_name := dir.get_next()
			while file_name != "":
				if dir.current_is_dir() and not file_name.begins_with("."):
					if current_dir == "res://" and file_name in exclude_dirs:
						pass
					else:
						dirs.append(current_dir.path_join(file_name))
				elif file_name.ends_with(".gd"):
					paths.append(current_dir.path_join(file_name))
				file_name = dir.get_next()
	return paths
