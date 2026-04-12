extends Node

const BACKGROUND_COLOR := Color("#2C3E50")
const BUTTON_RED := Color("#E74C3C")
const BUTTON_GREEN := Color("#2ECC71")
const BUTTON_BLUE := Color("#3498DB")
const BUTTON_YELLOW := Color("#F1C40F")
const BUTTON_COLORS: Array[Color] = [BUTTON_RED, BUTTON_GREEN, BUTTON_BLUE, BUTTON_YELLOW]
const CORRECT_HIGHLIGHT := Color("#27AE60")
const WRONG_HIGHLIGHT := Color("#C0392B")
const TEXT_COLOR := Color("#FFFFFF")
const TITLE_COLOR := Color("#ECF0F1")
const TIMER_GREEN := Color("#2ECC71")
const TIMER_YELLOW := Color("#F39C12")
const TIMER_RED := Color("#E74C3C")

const BASE_POINTS := 100
const TIME_BONUS_MULTIPLIER := 50.0
const ROUND_DURATION := 30.0

var high_score_quick: int = 0
var high_score_endless: int = 0
var _save_path := "user://save.json"


func _ready() -> void:
	load_data()


func calculate_score(question_time_remaining: float) -> int:
	var time_bonus := floori(question_time_remaining * TIME_BONUS_MULTIPLIER)
	return BASE_POINTS + time_bonus


func save_data() -> void:
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	if file:
		var data := {
			"high_score_quick": high_score_quick,
			"high_score_endless": high_score_endless,
		}
		file.store_string(JSON.stringify(data))


func load_data() -> void:
	if not FileAccess.file_exists(_save_path):
		return
	var file := FileAccess.open(_save_path, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error == OK and json.data is Dictionary:
		high_score_quick = int(json.data.get("high_score_quick", 0))
		high_score_endless = int(json.data.get("high_score_endless", 0))
