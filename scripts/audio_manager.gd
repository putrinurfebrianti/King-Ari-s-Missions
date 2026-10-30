extends Node

var master_volume: float = 1.0
var bgm_volume: float = 0.65
var sfx_volume: float = 0.85
var is_muted: bool = false

var bgm_player: AudioStreamPlayer
var horn_player: AudioStreamPlayer
var coin_player: AudioStreamPlayer
var crash_player: AudioStreamPlayer
var tick_player: AudioStreamPlayer
var victory_player: AudioStreamPlayer
var beep_player: AudioStreamPlayer
var go_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()

	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.school_delivered.connect(func(_idx, _name, _cnt, _tot, _c): play_coin_sfx())
		gm.mission_completed.connect(func(_s, _sc, _c): play_victory_sfx())
		gm.mission_failed.connect(func(_r): play_crash_sfx())
		gm.time_changed.connect(_on_time_changed)

	# Mulai musik latar belakang (BGM)
	start_bgm()

func _setup_audio_players() -> void:
	# 1. BGM Player (Musik Latar Melodi Menyetir Berulang / Looping)
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = _generate_driving_bgm(8.0)
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	add_child(bgm_player)

	# 2. Dual-Tone Klakson Mobil Resmi (A4 440Hz + C#5 554Hz)
	horn_player = AudioStreamPlayer.new()
	horn_player.stream = _generate_dual_tone(440.0, 554.37, 0.35, 0.7)
	horn_player.volume_db = linear_to_db(sfx_volume * master_volume)
	add_child(horn_player)

	# 3. Koin Perak Kerajaan (Denting Shimmer)
	coin_player = AudioStreamPlayer.new()
	coin_player.stream = _generate_shimmer_coin(987.77, 1318.5, 0.22)
	coin_player.volume_db = linear_to_db(sfx_volume * master_volume)
	add_child(coin_player)

	# 4. Benturan / Crash Thud
	crash_player = AudioStreamPlayer.new()
	crash_player.stream = _generate_tone_stream(120.0, 0.38, 0.8)
	crash_player.volume_db = linear_to_db(sfx_volume * master_volume)
	add_child(crash_player)

	# 5. Detak Jam Hitung Mundur (Tick-Tock)
	tick_player = AudioStreamPlayer.new()
	tick_player.stream = _generate_tone_stream(880.0, 0.06, 0.45)
	tick_player.volume_db = linear_to_db(sfx_volume * master_volume)
	add_child(tick_player)

	# 6. Fanfare Kemenangan
	victory_player = AudioStreamPlayer.new()
	victory_player.stream = _generate_victory_fanfare()
	victory_player.volume_db = linear_to_db(sfx_volume * master_volume)
	add_child(victory_player)

	# 7. Countdown Beep (3... 2... 1...)
	beep_player = AudioStreamPlayer.new()
	beep_player.stream = _generate_tone_stream(587.33, 0.14, 0.6) # D5 Beep
	beep_player.volume_db = linear_to_db(sfx_volume * master_volume)
	add_child(beep_player)

	# 8. Countdown GO! Chime
	go_player = AudioStreamPlayer.new()
	go_player.stream = _generate_dual_tone(880.0, 1108.73, 0.55, 0.75) # A5 + C#6 GO Chime
	go_player.volume_db = linear_to_db(sfx_volume * master_volume)
	add_child(go_player)

func start_bgm() -> void:
	if bgm_player and not bgm_player.playing and not is_muted:
		bgm_player.play()

func stop_bgm() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

func play_horn() -> void:
	if horn_player and not is_muted:
		horn_player.pitch_scale = randf_range(0.97, 1.03)
		horn_player.play()

func play_coin_sfx() -> void:
	if coin_player and not is_muted:
		coin_player.pitch_scale = randf_range(0.95, 1.15)
		coin_player.play()

func play_crash_sfx() -> void:
	if crash_player and not is_muted:
		crash_player.play()

func play_victory_sfx() -> void:
	if victory_player and not is_muted:
		victory_player.play()

func play_countdown_beep(is_go: bool = false) -> void:
	if is_muted:
		return
	if is_go:
		if go_player:
			go_player.play()
	else:
		if beep_player:
			beep_player.play()

var last_tick_second: int = -1
func _on_time_changed(seconds_left: float) -> void:
	if seconds_left < 60.0 and seconds_left > 0.0:
		var cur_sec = int(seconds_left)
		if cur_sec != last_tick_second:
			last_tick_second = cur_sec
			if tick_player and not is_muted:
				tick_player.play()

# Pengaturan Volume Master, BGM, dan SFX
func set_master_volume(val: float) -> void:
	master_volume = clamp(val, 0.0, 1.0)
	_update_bus_volumes()

func set_bgm_volume(val: float) -> void:
	bgm_volume = clamp(val, 0.0, 1.0)
	_update_bus_volumes()

func set_sfx_volume(val: float) -> void:
	sfx_volume = clamp(val, 0.0, 1.0)
	_update_bus_volumes()

func set_muted(muted: bool) -> void:
	is_muted = muted
	if is_muted:
		if bgm_player: bgm_player.stop()
	else:
		if bgm_player and not bgm_player.playing: bgm_player.play()
	_update_bus_volumes()

func _update_bus_volumes() -> void:
	if bgm_player:
		var eff_bgm = 0.0 if is_muted else (bgm_volume * master_volume)
		bgm_player.volume_db = linear_to_db(max(eff_bgm, 0.0001))

	var eff_sfx = 0.0 if is_muted else (sfx_volume * master_volume)
	var sfx_db = linear_to_db(max(eff_sfx, 0.0001))
	for p in [horn_player, coin_player, crash_player, tick_player, victory_player, beep_player, go_player]:
		if p: p.volume_db = sfx_db

# ----------------- Sintesis Audio Native Murni (AudioStreamWAV) -----------------

# Menghasilkan lagu mengemudi ceria berulang (BGM) 8 detik loop
func _generate_driving_bgm(duration: float = 8.0) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(total_samples)

	# 4 Pola Akord (C -> G -> Am -> F)
	var chord_roots = [261.63, 196.00, 220.00, 174.61] # C4, G3, A3, F3
	var chord_duration = duration / 4.0

	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var chord_idx = int(t / chord_duration) % 4
		var root = chord_roots[chord_idx]

		# 1. Bassline (Sawtooth lembut di root freq / 2)
		var bass_freq = root * 0.5
		var bass_wave = (fposmod(t * bass_freq, 1.0) * 2.0 - 1.0) * 0.22

		# 2. Arpeggio Ceria (Root -> Major/Minor 3rd -> 5th -> Octave)
		var arp_step = int(fmod(t * 8.0, 4.0)) # 8th notes
		var arp_mult = 1.0
		if arp_step == 1: arp_mult = 1.25 if (chord_idx != 2) else 1.20 # Major / Minor 3rd
		elif arp_step == 2: arp_mult = 1.5 # 5th
		elif arp_step == 3: arp_mult = 2.0 # Octave
		
		var arp_wave = sin(t * root * arp_mult * TAU) * 0.18

		# 3. Beat Drum Chiptune (Hi-hat click setiap seperempat ketuk)
		var beat_t = fmod(t, 0.25)
		var click = sin(beat_t * 1400.0 * TAU) * max(0.0, 1.0 - (beat_t * 28.0)) * 0.08

		var mixed = bass_wave + arp_wave + click
		var sample_val = int(clamp((mixed * 0.5 + 0.5) * 255.0, 0, 255))
		byte_data[i] = sample_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_samples
	return wav

# Nada Tunggal
func _generate_tone_stream(freq: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var envelope = 1.0 - (float(i) / float(num_samples))
		var wave = sin(t * freq * TAU) * volume * envelope
		var sample_val = int(clamp((wave + 1.0) * 0.5 * 255.0, 0, 255))
		byte_data[i] = sample_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_data
	return wav

# Nada Ganda (Dual Tone Klakson Mobil)
func _generate_dual_tone(freq1: float, freq2: float, duration: float, volume: float = 0.6) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = 1.0 - (float(i) / float(num_samples)) * 0.3
		var wave1 = sin(t * freq1 * TAU)
		var wave2 = sin(t * freq2 * TAU)
		var wave = (wave1 + wave2) * 0.5 * volume * env
		var sample_val = int(clamp((wave + 1.0) * 0.5 * 255.0, 0, 255))
		byte_data[i] = sample_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_data
	return wav

# Denting Koin Berkelap-Kelip (Shimmer Coin)
func _generate_shimmer_coin(freq1: float, freq2: float, duration: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = max(0.0, 1.0 - (t / duration))
		var current_freq = lerp(freq1, freq2, clamp(t / 0.08, 0.0, 1.0))
		var wave = sin(t * current_freq * TAU) * 0.6 * env
		var sample_val = int(clamp((wave + 1.0) * 0.5 * 255.0, 0, 255))
		byte_data[i] = sample_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_data
	return wav

# Jingle Fanfare Kemenangan (C -> E -> G -> High C)
func _generate_victory_fanfare() -> AudioStreamWAV:
	var duration = 1.5
	var sample_rate = 22050
	var num_samples = int(sample_rate * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples)

	var notes = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var note_idx = clamp(int(t / 0.32), 0, 3)
		var freq = notes[note_idx]
		var sub_t = fmod(t, 0.32)
		var env = 1.0 - (sub_t / 0.32) if (note_idx < 3) else max(0.0, 1.0 - ((t - 0.96) / 0.54))
		var wave = sin(t * freq * TAU) * 0.65 * env
		var sample_val = int(clamp((wave + 1.0) * 0.5 * 255.0, 0, 255))
		byte_data[i] = sample_val

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = byte_data
	return wav
