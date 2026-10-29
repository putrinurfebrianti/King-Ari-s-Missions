extends Node

var horn_player: AudioStreamPlayer
var coin_player: AudioStreamPlayer
var crash_player: AudioStreamPlayer
var tick_player: AudioStreamPlayer
var victory_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.school_delivered.connect(func(_idx, _name, _cnt, _tot, _c): play_coin_sfx())
		gm.mission_completed.connect(func(_s, _sc, _c): play_victory_sfx())
		gm.mission_failed.connect(func(_r): play_crash_sfx())
		gm.time_changed.connect(_on_time_changed)

func _setup_audio_players() -> void:
	horn_player = AudioStreamPlayer.new()
	horn_player.stream = _generate_tone_stream(440.0, 0.25, 0.6) # Tone A4 Klakson
	add_child(horn_player)

	coin_player = AudioStreamPlayer.new()
	coin_player.stream = _generate_tone_stream(987.77, 0.18, 0.5) # Tone B5 Denting Koin
	add_child(coin_player)

	crash_player = AudioStreamPlayer.new()
	crash_player.stream = _generate_tone_stream(130.81, 0.35, 0.7) # Low crash bump
	add_child(crash_player)

	tick_player = AudioStreamPlayer.new()
	tick_player.stream = _generate_tone_stream(880.0, 0.06, 0.4) # Short tick
	add_child(tick_player)

	victory_player = AudioStreamPlayer.new()
	victory_player.stream = _generate_tone_stream(587.33, 0.6, 0.6) # Victory tone
	add_child(victory_player)

func play_horn() -> void:
	if horn_player:
		horn_player.play()

func play_coin_sfx() -> void:
	if coin_player:
		coin_player.pitch_scale = randf_range(0.95, 1.15)
		coin_player.play()

func play_crash_sfx() -> void:
	if crash_player:
		crash_player.play()

func play_victory_sfx() -> void:
	if victory_player:
		victory_player.play()

var last_tick_second: int = -1
func _on_time_changed(seconds_left: float) -> void:
	if seconds_left < 60.0 and seconds_left > 0.0:
		var cur_sec = int(seconds_left)
		if cur_sec != last_tick_second:
			last_tick_second = cur_sec
			if tick_player:
				tick_player.play()

# Menghasilkan AudioStreamWAV secara sintetis murni (100% native tanpa file eksternal)
func _generate_tone_stream(freq: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var envelope = 1.0 - (float(i) / float(num_samples))
		var wave = sin(t * freq * TAU) * volume * envelope
		# 8-bit unsigned audio
		var sample_val = int(clamp((wave + 1.0) * 0.5 * 255.0, 0, 255))
		byte_data[i] = sample_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_data
	return wav
