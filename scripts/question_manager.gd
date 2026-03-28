extends Node

var questions_dir := "res://data/questions/"
var _questions: Array = []
var _remaining: Array = []
var _categories: Array = []


func load_questions() -> bool:
	_categories = _load_categories()
	_questions = []
	for cat: Dictionary in _categories:
		var slug: String = cat.get("slug", "")
		if slug.is_empty():
			continue
		var cat_questions := _load_category_file(slug)
		_questions.append_array(cat_questions)

	if _questions.is_empty():
		push_error("No questions loaded from %s" % questions_dir)
		return false
	reset()
	return true


func _load_categories() -> Array:
	var path := questions_dir + "categories.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to load %s" % path)
		return []
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		push_error("Failed to parse %s: %s" % [path, json.get_error_message()])
		return []
	if not json.data is Array:
		push_error("%s root must be an array" % path)
		return []
	return json.data


func _load_category_file(slug: String) -> Array:
	var path := questions_dir + slug + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("Could not load category file: %s" % path)
		return []
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		push_warning("Failed to parse %s: %s" % [path, json.get_error_message()])
		return []
	if not json.data is Array:
		push_warning("%s root must be an array" % path)
		return []
	return json.data


func reset() -> void:
	_remaining = _questions.duplicate()
	_remaining.shuffle()


func get_question_count() -> int:
	return _questions.size()


func has_next() -> bool:
	return _remaining.size() > 0


func next_question() -> Dictionary:
	if _remaining.is_empty():
		reset()
	var q: Dictionary = _remaining.pop_back()
	return _shuffle_answers(q)


func _shuffle_answers(q: Dictionary) -> Dictionary:
	var correct_text: String = q.get("answer", "")
	var answers: Array = [correct_text] + Array(q.get("distractors", []))
	answers.shuffle()
	var new_correct: int = answers.find(correct_text)
	return {
		"question": q.get("question", ""),
		"answers": answers,
		"correct": new_correct,
	}
