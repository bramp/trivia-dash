extends Node

const MAX_PLAYERS := 8

var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in range(MAX_PLAYERS):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play_correct() -> void:
	_play_tone(880.0, 0.1, -6.0)
	_play_tone_delayed(1108.73, 0.1, -6.0, 0.08)


func play_wrong() -> void:
	_play_tone(220.0, 0.25, -4.0)
	_play_tone_delayed(180.0, 0.3, -4.0, 0.1)


func play_tick() -> void:
	_play_tone(1200.0, 0.03, -12.0)


func play_button_tap() -> void:
	_play_tone(660.0, 0.05, -10.0)


func play_game_over() -> void:
	_play_tone(440.0, 0.2, -4.0)
	_play_tone_delayed(370.0, 0.2, -4.0, 0.15)
	_play_tone_delayed(330.0, 0.3, -4.0, 0.3)


func play_new_high_score() -> void:
	_play_tone(523.25, 0.15, -6.0)
	_play_tone_delayed(659.25, 0.15, -6.0, 0.12)
	_play_tone_delayed(783.99, 0.15, -6.0, 0.24)
	_play_tone_delayed(1046.50, 0.25, -6.0, 0.36)


func _play_tone(freq: float, duration: float, volume_db: float) -> void:
	var player := _get_free_player()
	if not player:
		return
	var sample_rate := 44100.0
	var num_samples := int(sample_rate * duration)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = int(sample_rate)
	audio.stereo = false

	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var envelope := 1.0 - (float(i) / float(num_samples))
		envelope = envelope * envelope
		var sample := sin(t * freq * TAU) * envelope * 0.8
		var sample_int := clampi(int(sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	audio.data = data
	player.stream = audio
	player.volume_db = volume_db
	player.play()


func _play_tone_delayed(freq: float, duration: float, volume_db: float, delay: float) -> void:
	get_tree().create_timer(delay).timeout.connect(_play_tone.bind(freq, duration, volume_db))


func _get_free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	return _players[0]
