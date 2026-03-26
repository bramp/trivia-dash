extends Node

var _questions: Array = []
var _remaining: Array = []


func load_questions() -> void:
	var file := FileAccess.open("res://data/questions.json", FileAccess.READ)
	if not file:
		push_error("Failed to load questions.json")
		return
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		push_error("Failed to parse questions.json: " + json.get_error_message())
		return
	if not json.data is Array:
		push_error("questions.json root must be an array")
		return
	_questions = json.data
	reset()


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
	var answers: Array = q.get("answers", []).duplicate()
	var correct_text: String = answers[q.get("correct", 0)]
	answers.shuffle()
	var new_correct: int = answers.find(correct_text)
	return {
		"question": q.get("question", ""),
		"answers": answers,
		"correct": new_correct,
	}


func get_question_count() -> int:
	return _questions.size()
