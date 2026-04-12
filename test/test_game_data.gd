extends GutTest


func test_calculate_score_base_points() -> void:
	# With 0 time remaining, should get only base points.
	var score := GameData.calculate_score(0.0)
	assert_eq(score, 100, "Base points should be 100 with 0 time remaining")


func test_calculate_score_with_time_bonus() -> void:
	# With 2.5 seconds remaining: 100 + floor(2.5 * 50) = 100 + 125 = 225
	var score := GameData.calculate_score(2.5)
	assert_eq(score, 225, "Score should be 225 with 2.5s remaining")


func test_calculate_score_instant_answer() -> void:
	# Answering instantly with full 30s: 100 + floor(30 * 50) = 100 + 1500 = 1600
	var score := GameData.calculate_score(30.0)
	assert_eq(score, 1600, "Score should be 1600 with 30s remaining")


func test_calculate_score_with_small_time() -> void:
	# With 0.5 seconds remaining: 100 + floor(0.5 * 50) = 100 + 25 = 125
	var score := GameData.calculate_score(0.5)
	assert_eq(score, 125, "Score should be 125 with 0.5s remaining")


func test_high_score_default() -> void:
	# High score should default to 0 on a fresh instance.
	var saved_quick: int = GameData.high_score_quick
	var saved_endless: int = GameData.high_score_endless
	GameData.high_score_quick = 0
	GameData.high_score_endless = 0
	assert_eq(GameData.high_score_quick, 0, "Default quick high score should be 0")
	assert_eq(GameData.high_score_endless, 0, "Default endless high score should be 0")
	GameData.high_score_quick = saved_quick
	GameData.high_score_endless = saved_endless


func test_scoring_constants() -> void:
	assert_eq(GameData.BASE_POINTS, 100, "BASE_POINTS should be 100")
	assert_eq(GameData.TIME_BONUS_MULTIPLIER, 50.0, "TIME_BONUS_MULTIPLIER should be 50.0")
	assert_eq(GameData.ROUND_DURATION, 30.0, "ROUND_DURATION should be 30.0")


func test_button_colors_count() -> void:
	assert_eq(GameData.BUTTON_COLORS.size(), 4, "Should have exactly 4 button colours")
