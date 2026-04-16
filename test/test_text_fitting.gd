extends GutTest
## Automated tests that verify all question and answer text fits within the UI
## at various resolutions without being truncated or hitting the minimum font size.

const MIN_QUESTION_FONT := 24
const MIN_ANSWER_FONT := 18

# Maximum character limits for data quality.
const MAX_QUESTION_LENGTH := 150
const MAX_ANSWER_LENGTH := 100

# Resolutions to test (width × height).
const TEST_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(3840, 2160),
	Vector2i(390, 844),
	Vector2i(1024, 768),
]

var _main_scene: Control = null
var _manager: Node = null


func before_all() -> void:
	# Load the full main scene so theme, layout, and controls are available.
	var scene: PackedScene = load("res://scenes/main.tscn")
	_main_scene = scene.instantiate()
	add_child(_main_scene)
	# Wait one frame for layout.
	await get_tree().process_frame

	# Load production questions via a separate QuestionManager so we read
	# from the real data directory.
	_manager = load("res://scripts/question_manager.gd").new()
	_manager.questions_dir = "res://data/questions/"
	add_child(_manager)
	_manager.load_questions()


func after_all() -> void:
	if _main_scene:
		_main_scene.free()
		_main_scene = null
	if _manager:
		_manager.free()
		_manager = null


# --- Data quality tests ---


func test_question_text_length_limits() -> void:
	var questions := _load_all_raw_questions()
	for q: Dictionary in questions:
		var text: String = q.get("question", "")
		assert_lt(
			text.length(),
			MAX_QUESTION_LENGTH,
			"Question too long (%d chars): %s" % [text.length(), text.left(60)],
		)


func test_answer_text_length_limits() -> void:
	var questions := _load_all_raw_questions()
	for q: Dictionary in questions:
		var answer: String = q.get("answer", "")
		assert_lt(
			answer.length(),
			MAX_ANSWER_LENGTH,
			"Answer too long (%d chars): %s" % [answer.length(), answer.left(60)],
		)
		for d: String in q.get("distractors", []):
			assert_lt(
				d.length(),
				MAX_ANSWER_LENGTH,
				"Distractor too long (%d chars): %s" % [d.length(), d.left(60)],
			)


func test_all_questions_have_four_answers() -> void:
	var questions := _load_all_raw_questions()
	for q: Dictionary in questions:
		var count: int = 1 + q.get("distractors", []).size()
		assert_eq(
			count,
			4,
			"Question should have 1 answer + 3 distractors: %s" % q.get("question", ""),
		)


# --- Font fitting tests at multiple resolutions ---


func test_text_fits_at_all_resolutions() -> void:
	if _manager.get_question_count() == 0:
		pass_test("No production questions found, skipping fit test")
		return

	var question_label: Label = _main_scene.get_node("GameScreen/Content/QuestionContainer/QuestionLabel")
	var answer_btns: Array[Button] = [
		_main_scene.get_node("GameScreen/Content/AnswersContainer/AnswerGrid/Answer1"),
		_main_scene.get_node("GameScreen/Content/AnswersContainer/AnswerGrid/Answer2"),
		_main_scene.get_node("GameScreen/Content/AnswersContainer/AnswerGrid/Answer3"),
		_main_scene.get_node("GameScreen/Content/AnswersContainer/AnswerGrid/Answer4"),
	]

	# Make game screen visible so layout is computed.
	_main_scene.get_node("TitleScreen").visible = false
	_main_scene.get_node("GameOverScreen").visible = false
	_main_scene.get_node("GameScreen").visible = true

	for res: Vector2i in TEST_RESOLUTIONS:
		# Resize the viewport to simulate different screen sizes.
		get_tree().root.content_scale_size = res
		await get_tree().process_frame
		await get_tree().process_frame

		_manager.reset()
		var tested := 0
		while _manager.has_next():
			var q: Dictionary = _manager.next_question()
			var q_text: String = q.get("question", "")
			var answers: Array = q.get("answers", [])

			# Test question fitting.
			question_label.remove_theme_font_size_override("font_size")
			question_label.text = q_text
			var q_fitted: int = _main_scene._calc_fitting_font_size(question_label, q_text, MIN_QUESTION_FONT)
			assert_gte(
				q_fitted,
				MIN_QUESTION_FONT,
				"Question font below minimum at %dx%d: %s" % [res.x, res.y, q_text.left(60)],
			)

			# Test answer fitting — find the smallest fitted size across all 4.
			var min_fitted: int = answer_btns[0].get_theme_font_size("font_size")
			for i in range(answer_btns.size()):
				var btn := answer_btns[i]
				btn.remove_theme_font_size_override("font_size")
				btn.text = answers[i] if i < answers.size() else ""
				var fitted: int = _main_scene._calc_fitting_font_size(btn, btn.text, MIN_ANSWER_FONT)
				if fitted < min_fitted:
					min_fitted = fitted

			assert_gte(
				min_fitted,
				MIN_ANSWER_FONT,
				"Answer font below minimum at %dx%d for: %s" % [res.x, res.y, q_text.left(40)],
			)
			tested += 1

		assert_gt(tested, 0, "Should have tested at least one question at %dx%d" % [res.x, res.y])

	# Restore original content scale.
	get_tree().root.content_scale_size = Vector2i(1280, 720)


# --- Helpers ---


func _load_all_raw_questions() -> Array:
	var all: Array = []
	var cat_path := "res://data/questions/categories.json"
	var cat_file := FileAccess.open(cat_path, FileAccess.READ)
	if not cat_file:
		return all
	var json := JSON.new()
	if json.parse(cat_file.get_as_text()) != OK:
		return all
	for cat: Dictionary in json.data:
		var slug: String = cat.get("slug", "")
		if slug.is_empty():
			continue
		var path := "res://data/questions/" + slug + ".json"
		var file := FileAccess.open(path, FileAccess.READ)
		if not file:
			continue
		var qjson := JSON.new()
		if qjson.parse(file.get_as_text()) != OK:
			continue
		if qjson.data is Array:
			all.append_array(qjson.data)
	return all
