extends GutTest

var _manager: Node = null


func before_each() -> void:
	_manager = load("res://scripts/question_manager.gd").new()
	add_child_autofree(_manager)


func test_load_questions_populates_array() -> void:
	_manager.load_questions()
	assert_gt(_manager.get_question_count(), 0, "Should load at least one question")


func test_load_questions_count() -> void:
	_manager.load_questions()
	assert_eq(_manager.get_question_count(), 10, "Should load exactly 10 test questions")


func test_next_question_returns_valid_dict() -> void:
	_manager.load_questions()
	var q: Dictionary = _manager.next_question()
	assert_has(q, "question", "Should have 'question' key")
	assert_has(q, "answers", "Should have 'answers' key")
	assert_has(q, "correct", "Should have 'correct' key")


func test_next_question_has_four_answers() -> void:
	_manager.load_questions()
	var q: Dictionary = _manager.next_question()
	assert_eq(q.answers.size(), 4, "Should have exactly 4 answers")


func test_correct_index_points_to_right_answer() -> void:
	# Load questions and verify the correct index always points to a valid answer.
	_manager.load_questions()
	# Run multiple times to account for shuffle randomness.
	for i in range(20):
		_manager.reset()
		var q: Dictionary = _manager.next_question()
		var correct_idx: int = q.correct
		assert_gte(correct_idx, 0, "Correct index should be >= 0")
		assert_lt(correct_idx, 4, "Correct index should be < 4")
		# The answer at the correct index should be a non-empty string.
		assert_ne(q.answers[correct_idx], "", "Correct answer should not be empty")


func test_no_repeat_until_pool_exhausted() -> void:
	_manager.load_questions()
	var seen_questions: Array[String] = []
	var count: int = _manager.get_question_count()
	for i in range(count):
		var q: Dictionary = _manager.next_question()
		assert_does_not_have(seen_questions, q.question, "Should not repeat question")
		seen_questions.append(q.question)


func test_has_next_returns_false_when_exhausted() -> void:
	_manager.load_questions()
	var count: int = _manager.get_question_count()
	for i in range(count):
		_manager.next_question()
	assert_false(_manager.has_next(), "Should have no more questions after exhausting pool")


func test_reset_refills_pool() -> void:
	_manager.load_questions()
	var count: int = _manager.get_question_count()
	for i in range(count):
		_manager.next_question()
	_manager.reset()
	assert_true(_manager.has_next(), "Should have questions again after reset")


func test_shuffle_changes_answer_order() -> void:
	# Load multiple times and check that at least one question has shuffled answers.
	_manager.load_questions()
	var found_different := false
	for i in range(20):
		_manager.reset()
		# Go through all questions looking for any with shuffled answers.
		while _manager.has_next():
			var q: Dictionary = _manager.next_question()
			if q.question == "What is the capital of France?":
				var original := ["Paris", "London", "Berlin", "Madrid"]
				if q.answers != original:
					found_different = true
					break
		if found_different:
			break
	# It's possible (but extremely unlikely at 1/24^20) that shuffle never changes order.
	assert_true(found_different, "Shuffle should change answer order at least once in 20 tries")
