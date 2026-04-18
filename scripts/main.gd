extends Control

enum State { TITLE, PLAYING, GAME_OVER }
enum GameMode { QUICK, ENDLESS }

const BuildInfo = preload("res://scripts/build_info.gd")

# Debug: preset resolutions to cycle with F3
const _DEBUG_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(3840, 2160),
	Vector2i(390, 844),
	Vector2i(1024, 768),
]

var _state: State = State.TITLE
var _game_mode: GameMode = GameMode.QUICK
var _score: int = 0
var _time_remaining: float = 0.0
var _question_start_msec: float = 0.0
var _current_question: Dictionary = {}
var _input_locked: bool = false
var _active_tween: Tween = null
var _debug_res_index: int = 0

@onready var title_screen: MarginContainer = $TitleScreen
@onready var game_screen: MarginContainer = $GameScreen
@onready var game_over_screen: MarginContainer = $GameOverScreen
@onready var question_manager: Node = $QuestionManager
@onready var game_timer: Timer = $GameTimer

# Title screen
@onready var title_label: Label = $TitleScreen/Content/TitleLabel
@onready var subtitle_label: Label = $TitleScreen/Content/SubtitleLabel
@onready var quick_play_button: Button = $TitleScreen/Content/QuickPlayButton
@onready var endless_play_button: Button = $TitleScreen/Content/EndlessPlayButton
@onready var title_high_score_label: Label = $TitleScreen/Content/HighScoreLabel
@onready var build_info_label: Label = $TitleScreen/Content/BuildInfoLabel

# Game screen
@onready var score_label: Label = $GameScreen/Content/TopBar/ScoreLabel
@onready var timer_label: Label = $GameScreen/Content/TopBar/TimerLabel
@onready var timer_bar: ProgressBar = $GameScreen/Content/TimerBar
@onready var question_label: Label = $GameScreen/Content/QuestionContainer/QuestionLabel
@onready var answer_buttons: Array[Button] = [
	$GameScreen/Content/AnswersContainer/AnswerGrid/Answer1,
	$GameScreen/Content/AnswersContainer/AnswerGrid/Answer2,
	$GameScreen/Content/AnswersContainer/AnswerGrid/Answer3,
	$GameScreen/Content/AnswersContainer/AnswerGrid/Answer4,
]

# Game over screen
@onready var game_over_label: Label = $GameOverScreen/Content/GameOverLabel
@onready var final_score_label: Label = $GameOverScreen/Content/FinalScoreLabel
@onready var game_over_high_score_label: Label = $GameOverScreen/Content/HighScoreLabel
@onready var new_high_score_label: Label = $GameOverScreen/Content/NewHighScoreLabel
@onready var play_again_button: Button = $GameOverScreen/Content/PlayAgainButton
@onready var main_menu_button: Button = $GameOverScreen/Content/MainMenuButton


func _ready() -> void:
	var loaded: bool = question_manager.load_questions()
	_show_title_screen()
	if not loaded:
		subtitle_label.text = "Error: No questions found!"
		quick_play_button.disabled = true
		endless_play_button.disabled = true


func _unhandled_input(event: InputEvent) -> void:
	# Debug: F3 cycles through preset resolutions (desktop only).
	if OS.has_feature("debug") and event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		var res := _DEBUG_RESOLUTIONS[_debug_res_index]
		get_window().size = res
		get_window().content_scale_size = get_window().content_scale_size  # force re-layout
		_debug_res_index = (_debug_res_index + 1) % _DEBUG_RESOLUTIONS.size()
		print("Debug: window resized to %dx%d" % [res.x, res.y])
		get_viewport().set_input_as_handled()
		return

	if _state != State.PLAYING or _input_locked:
		return
	if event.is_action_pressed("answer_1"):
		_on_answer_pressed(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("answer_2"):
		_on_answer_pressed(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("answer_3"):
		_on_answer_pressed(2)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("answer_4"):
		_on_answer_pressed(3)
		get_viewport().set_input_as_handled()


func _on_game_timer_timeout() -> void:
	if _game_mode != GameMode.QUICK:
		return
	_time_remaining -= game_timer.wait_time
	_time_remaining = maxf(_time_remaining, 0.0)
	_update_timer_display()
	if _time_remaining <= 0.0:
		game_timer.stop()
		_end_game()
	elif _time_remaining <= 5.0 and fmod(_time_remaining, 1.0) < game_timer.wait_time:
		SfxManager.play_tick()


func _on_quick_play_pressed() -> void:
	SfxManager.play_button_tap()
	_start_game(GameMode.QUICK)


func _on_endless_play_pressed() -> void:
	SfxManager.play_button_tap()
	_start_game(GameMode.ENDLESS)


func _on_play_again_pressed() -> void:
	SfxManager.play_button_tap()
	_start_game(_game_mode)


func _on_main_menu_pressed() -> void:
	SfxManager.play_button_tap()
	_show_title_screen()


func _on_answer_pressed(index: int) -> void:
	if _state != State.PLAYING or _input_locked:
		return
	_input_locked = true
	var elapsed := (Time.get_ticks_msec() - _question_start_msec) / 1000.0

	var effective_remaining := 0.0
	if _game_mode == GameMode.QUICK:
		var question_time_left := maxf(0.0, _time_remaining)
		effective_remaining = minf(maxf(0.0, 5.0 - elapsed), question_time_left)  # Bonus up to 5s of value for quick answer
	else:
		effective_remaining = maxf(0.0, 5.0 - elapsed)
	if index == _current_question.get("correct", -1):
		_handle_correct_answer(index, effective_remaining)
	else:
		_handle_wrong_answer(index)


# --- State transitions ---


func _show_title_screen() -> void:
	_state = State.TITLE
	game_screen.visible = false
	game_over_screen.visible = false
	title_screen.visible = true

	title_high_score_label.text = (
		"High Scores - Quick: %d | Endless: %d" % [GameData.high_score_quick, GameData.high_score_endless]
	)

	build_info_label.text = "Build: %s" % BuildInfo.BUILD_DATE

	_animate_title_entrance()
	quick_play_button.grab_focus()


func _start_game(mode: GameMode) -> void:
	_game_mode = mode
	_state = State.PLAYING
	_score = 0
	_input_locked = false
	question_manager.reset()

	title_screen.visible = false
	game_over_screen.visible = false
	game_screen.visible = true

	if mode == GameMode.QUICK:
		_time_remaining = GameData.ROUND_DURATION
		timer_bar.visible = true
		timer_label.visible = true
		_update_timer_display()
		game_timer.start()
	else:
		_time_remaining = 0.0
		timer_bar.visible = false
		timer_label.visible = false
		game_timer.stop()

	_update_score_display()
	_show_next_question()


func _end_game() -> void:
	_state = State.GAME_OVER
	_input_locked = true
	game_timer.stop()

	var is_new_high := false
	if _game_mode == GameMode.QUICK:
		is_new_high = _score > GameData.high_score_quick
		if is_new_high:
			GameData.high_score_quick = _score
			GameData.save_data()
	else:
		is_new_high = _score > GameData.high_score_endless
		if is_new_high:
			GameData.high_score_endless = _score
			GameData.save_data()

	SfxManager.play_game_over()

	# Transition to game over after a brief delay.
	var delay_tween := create_tween()
	delay_tween.tween_interval(0.5)
	delay_tween.tween_callback(_show_game_over_screen.bind(is_new_high))


func _show_game_over_screen(is_new_high: bool) -> void:
	game_screen.visible = false
	title_screen.visible = false
	game_over_screen.visible = true

	final_score_label.text = "Score: %d" % _score
	if _game_mode == GameMode.QUICK:
		game_over_high_score_label.text = "High Score (Quick): %d" % GameData.high_score_quick
	else:
		game_over_high_score_label.text = "High Score (Endless): %d" % GameData.high_score_endless
	new_high_score_label.visible = is_new_high
	if is_new_high:
		SfxManager.play_new_high_score()

	_animate_game_over_entrance()
	play_again_button.grab_focus()


# --- Question flow ---


func _show_next_question() -> void:
	if not question_manager.has_next():
		question_manager.reset()
	_current_question = question_manager.next_question()
	_question_start_msec = Time.get_ticks_msec()
	_display_question(_current_question)
	_input_locked = false


func _display_question(q: Dictionary) -> void:
	question_label.text = q.get("question", "")
	# Reset question font size override so theme size is used, then auto-fit after layout.
	question_label.remove_theme_font_size_override("font_size")

	var answers: Array = q.get("answers", [])
	var correct_idx: int = q.get("correct", -1)
	for i in range(answer_buttons.size()):
		var btn := answer_buttons[i]
		var label: String = answers[i] if i < answers.size() else ""
		if OS.has_feature("debug") and i == correct_idx:
			label = "★ " + label
		btn.text = label
		btn.disabled = false
		btn.modulate.a = 1.0
		btn.scale = Vector2.ONE
		# Reset font size override so theme size is used, then auto-fit after layout.
		btn.remove_theme_font_size_override("font_size")
		# Remove any overlay labels (e.g. ✗ from wrong answers).
		for child in btn.get_children():
			if child is Label:
				child.queue_free()
		# Reset button style to default colour.
		btn.remove_theme_stylebox_override("disabled")
		btn.remove_theme_color_override("font_disabled_color")
		var style := btn.get_theme_stylebox("normal") as StyleBoxFlat
		if style:
			style.bg_color = GameData.BUTTON_COLORS[i]
			# Only clear borders if NOT focused, to avoid flickering focus style.
			if not btn.has_focus():
				style.border_width_left = 0
				style.border_width_right = 0
				style.border_width_top = 0
				style.border_width_bottom = 0

	# Auto-fit text after one layout pass so sizes are known.
	_auto_fit_text.call_deferred()
	_animate_question_entrance()
	answer_buttons[0].grab_focus()


func _handle_correct_answer(index: int, time_remaining: float) -> void:
	var points := GameData.calculate_score(time_remaining)
	_score += points
	_update_score_display()
	SfxManager.play_correct()
	_animate_correct(index)
	_spawn_floating_score(answer_buttons[index], points)

	# After correct animation, show next question.
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(_animate_question_exit)
	tween.tween_interval(0.3)
	tween.tween_callback(_show_next_question)


func _handle_wrong_answer(index: int) -> void:
	SfxManager.play_wrong()
	var correct_index: int = _current_question.get("correct", -1)
	_animate_wrong(index, correct_index)
	# Brief pause then game over.
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(_end_game)


# --- Display updates ---


func _update_score_display() -> void:
	score_label.text = "Score: %d" % _score
	_animate_score_pop()


func _update_timer_display() -> void:
	timer_label.text = "%.1f" % _time_remaining
	timer_bar.value = _time_remaining

	# Update timer bar colour.
	var fill_style := timer_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		var ratio := _time_remaining / GameData.ROUND_DURATION
		if ratio > 0.5:
			fill_style.bg_color = GameData.TIMER_GREEN.lerp(GameData.TIMER_YELLOW, 1.0 - ratio * 2.0)
		else:
			fill_style.bg_color = GameData.TIMER_YELLOW.lerp(GameData.TIMER_RED, 1.0 - ratio * 2.0)


## Compute the largest font size (down to [param min_size]) at which [param text]
## fits inside [param ctrl]. Returns the base theme size if no shrinking is needed.
func _calc_fitting_font_size(ctrl: Control, text: String, min_size: int = 16) -> int:
	var font := ctrl.get_theme_font("font")
	var base_size := ctrl.get_theme_font_size("font_size")
	var style := ctrl.get_theme_stylebox("normal") as StyleBoxFlat
	var margin_h := 0.0
	var margin_v := 0.0
	if style:
		margin_h = style.content_margin_left + style.content_margin_right
		margin_v = style.content_margin_top + style.content_margin_bottom
	var avail := Vector2(ctrl.size.x - margin_h, ctrl.size.y - margin_v)
	if avail.x <= 0 or avail.y <= 0:
		return base_size
	var font_size := base_size
	while font_size >= min_size:
		var text_size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, avail.x, font_size)
		if text_size.y <= avail.y:
			break
		font_size -= 2
	return max(font_size, min_size)


## Called via call_deferred after layout so control sizes are known.
## Shrinks font sizes to fit, using the same size for all answer buttons.
func _auto_fit_text() -> void:
	# Fit question label independently.
	var q_size := _calc_fitting_font_size(question_label, question_label.text, 24)
	var q_base := question_label.get_theme_font_size("font_size")
	if q_size < q_base:
		question_label.add_theme_font_size_override("font_size", q_size)

	# Find the smallest font size needed across all four answer buttons,
	# then apply it uniformly so all buttons match.
	var min_btn_size: int = answer_buttons[0].get_theme_font_size("font_size")
	for btn in answer_buttons:
		var fitted := _calc_fitting_font_size(btn, btn.text, 18)
		if fitted < min_btn_size:
			min_btn_size = fitted
	var btn_base := answer_buttons[0].get_theme_font_size("font_size")
	if min_btn_size < btn_base:
		for btn in answer_buttons:
			btn.add_theme_font_size_override("font_size", min_btn_size)


# --- Animations ---


func _kill_active_tween() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null


func _animate_title_entrance() -> void:
	# Title slides down + fades in.
	title_label.modulate.a = 0.0
	title_label.position.y -= 50
	subtitle_label.modulate.a = 0.0
	quick_play_button.modulate.a = 0.0
	quick_play_button.scale = Vector2.ZERO
	endless_play_button.modulate.a = 0.0
	endless_play_button.scale = Vector2.ZERO
	title_high_score_label.modulate.a = 0.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(title_label, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(title_label, "position:y", title_label.position.y + 50, 0.4)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.3)
	tween.tween_property(quick_play_button, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(quick_play_button, "scale", Vector2.ONE, 0.3)
	tween.tween_property(endless_play_button, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(endless_play_button, "scale", Vector2.ONE, 0.3)
	tween.tween_property(title_high_score_label, "modulate:a", 1.0, 0.3)


func _animate_question_entrance() -> void:
	_kill_active_tween()
	# Question slides down + fades in.
	question_label.modulate.a = 0.0
	question_label.position.y -= 30

	_active_tween = create_tween()
	_active_tween.set_ease(Tween.EASE_OUT)
	_active_tween.set_trans(Tween.TRANS_CUBIC)

	_active_tween.tween_property(question_label, "modulate:a", 1.0, 0.3)
	_active_tween.parallel().tween_property(question_label, "position:y", question_label.position.y + 30, 0.3)

	# Staggered button entrance.
	for i in range(answer_buttons.size()):
		var btn := answer_buttons[i]
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.8, 0.8)
		btn.pivot_offset = btn.size / 2.0

		var delay := 0.15 + i * 0.05
		_active_tween.parallel().tween_property(btn, "modulate:a", 1.0, 0.2).set_delay(delay)
		(
			_active_tween
			. parallel()
			. tween_property(btn, "scale", Vector2.ONE, 0.25)
			. set_delay(delay)
			. set_ease(Tween.EASE_OUT)
			. set_trans(Tween.TRANS_BACK)
		)


func _animate_question_exit() -> void:
	_kill_active_tween()
	_active_tween = create_tween()
	_active_tween.set_ease(Tween.EASE_IN)
	_active_tween.set_trans(Tween.TRANS_CUBIC)

	_active_tween.tween_property(question_label, "modulate:a", 0.0, 0.2)
	_active_tween.parallel().tween_property(question_label, "position:x", question_label.position.x - 60, 0.2)

	for i in range(answer_buttons.size()):
		var btn := answer_buttons[i]
		var delay := i * 0.03
		_active_tween.parallel().tween_property(btn, "modulate:a", 0.0, 0.15).set_delay(delay)
		_active_tween.parallel().tween_property(btn, "position:x", btn.position.x - 60, 0.15).set_delay(delay)

	# Reset positions after exit.
	_active_tween.tween_callback(_reset_question_positions)


func _reset_question_positions() -> void:
	question_label.position.x += 60
	for btn in answer_buttons:
		btn.position.x += 60


func _animate_correct(index: int) -> void:
	var btn := answer_buttons[index]
	btn.pivot_offset = btn.size / 2.0

	# Flash the button bright green with white border.
	var style := btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	style.bg_color = GameData.CORRECT_HIGHLIGHT.lightened(0.2)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color.WHITE
	btn.add_theme_stylebox_override("normal", style)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.18)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.15)

	# Spawn celebratory emoji particles around the button.
	_spawn_celebration_particles(btn)

	# Restore original colour after animation completes via the next question display.


func _spawn_floating_score(btn: Button, points: int) -> void:
	var float_label := Label.new()
	float_label.text = "+%d" % points
	float_label.add_theme_font_size_override("font_size", 44)
	float_label.add_theme_color_override("font_color", Color.WHITE)
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.z_index = 10
	add_child(float_label)

	float_label.global_position = Vector2(
		btn.global_position.x + btn.size.x / 2.0 - 40,
		btn.global_position.y - 20,
	)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(float_label, "global_position:y", float_label.global_position.y - 80, 0.6)
	tween.tween_property(float_label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(float_label.queue_free)


func _spawn_celebration_particles(btn: Button) -> void:
	var symbols := ["🎉", "⭐", "✨", "💥", "🔥", "✓"]
	var colors: Array[Color] = [
		Color("#2ECC71"),
		Color("#F1C40F"),
		Color("#E74C3C"),
		Color("#3498DB"),
		Color("#FFFFFF"),
		Color("#E67E22"),
	]
	var center := Vector2(
		btn.global_position.x + btn.size.x / 2.0,
		btn.global_position.y + btn.size.y / 2.0,
	)
	var particle_count := 14
	for i in range(particle_count):
		var particle := Label.new()
		particle.text = symbols[i % symbols.size()]
		particle.add_theme_font_size_override("font_size", 38)
		particle.add_theme_color_override("font_color", colors[i % colors.size()])
		particle.z_index = 10
		add_child(particle)

		particle.global_position = center
		var angle := i * TAU / float(particle_count)
		var radius := 120.0 + randf_range(-20.0, 20.0)
		var target := center + Vector2(cos(angle), sin(angle)) * radius

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", target, 0.5).set_ease(Tween.EASE_OUT).set_trans(
			Tween.TRANS_CUBIC
		)
		# Spin the particle for flair.
		particle.pivot_offset = Vector2(10, 10)
		tween.tween_property(particle, "rotation", randf_range(-PI, PI), 0.5)
		tween.tween_property(particle, "modulate:a", 0.0, 0.35).set_delay(0.2)
		tween.chain().tween_callback(particle.queue_free)


func _animate_wrong(index: int, correct_index: int) -> void:
	var btn := answer_buttons[index]

	# Disable all buttons.
	for b in answer_buttons:
		b.disabled = true

	# Grey out all buttons except the correct one.
	var grey := Color(0.3, 0.3, 0.3, 0.6)
	for i in range(answer_buttons.size()):
		var b := answer_buttons[i]
		if i == correct_index:
			# Keep the correct button in its original color even when disabled.
			var original := b.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			b.add_theme_stylebox_override("disabled", original)
			b.add_theme_color_override("font_disabled_color", GameData.TEXT_COLOR)
			continue
		var dimmed := b.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		dimmed.bg_color = grey
		b.add_theme_stylebox_override("normal", dimmed)
		b.add_theme_stylebox_override("disabled", dimmed)
		b.modulate.a = 0.5

	# Overlay a red ✗ on the wrong button.
	var x_label := Label.new()
	x_label.text = "✗"
	x_label.add_theme_font_size_override("font_size", 216)
	x_label.add_theme_color_override("font_color", Color(0.9, 0.15, 0.15))
	x_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	x_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	x_label.z_index = 10
	x_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(x_label)
	x_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	# Shake animation on the wrong button.
	var original_x := btn.position.x
	var tween := create_tween()
	for cycle in range(3):
		tween.tween_property(btn, "position:x", original_x + 8, 0.05)
		tween.tween_property(btn, "position:x", original_x - 8, 0.05)
	tween.tween_property(btn, "position:x", original_x, 0.05)

	# Pulse the correct answer so it stands out.
	if correct_index >= 0 and correct_index < answer_buttons.size():
		var correct_btn := answer_buttons[correct_index]
		correct_btn.pivot_offset = correct_btn.size / 2.0
		var pulse := create_tween()
		pulse.set_ease(Tween.EASE_IN_OUT)
		pulse.set_trans(Tween.TRANS_SINE)
		pulse.tween_property(correct_btn, "scale", Vector2(1.08, 1.08), 0.25)
		pulse.tween_property(correct_btn, "scale", Vector2.ONE, 0.25)


func _animate_score_pop() -> void:
	score_label.pivot_offset = score_label.size / 2.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(score_label, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.08)


func _animate_game_over_entrance() -> void:
	game_over_label.modulate.a = 0.0
	game_over_label.scale = Vector2(0.5, 0.5)
	game_over_label.pivot_offset = game_over_label.size / 2.0
	final_score_label.modulate.a = 0.0
	game_over_high_score_label.modulate.a = 0.0
	new_high_score_label.modulate.a = 0.0
	play_again_button.modulate.a = 0.0
	main_menu_button.modulate.a = 0.0

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(game_over_label, "modulate:a", 1.0, 0.4)
	tween.parallel().tween_property(game_over_label, "scale", Vector2.ONE, 0.4)
	tween.tween_property(final_score_label, "modulate:a", 1.0, 0.3)
	tween.tween_property(game_over_high_score_label, "modulate:a", 1.0, 0.2)

	if new_high_score_label.visible:
		tween.tween_property(new_high_score_label, "modulate:a", 1.0, 0.3)

	tween.tween_property(play_again_button, "modulate:a", 1.0, 0.25)
	tween.tween_property(main_menu_button, "modulate:a", 1.0, 0.25)
