extends CharacterBody3D

enum ControlMode {
	SCREEN_DIRECT, # Mode Arah Layar (W=Atas, S=Bawah, A=Kiri, D=Kanan) - Intuitif & Alami
	CLASSIC_STEER  # Mode Simulator Klasik (W=Gas, S=Rem/Mundur, A=Kiri, D=Kanan)
}

const AUDIO_STREAM_PATHS := {
	"brake": "res://assets/audio/brake.mp3",
	"collision": "res://assets/audio/collision.mp3",
	"engine_driving": "res://assets/audio/engine_driving.mp3",
	"engine_start": "res://assets/audio/engine_start.mp3",
	"mission_complete": "res://assets/audio/mission_complete.mp3",
	"reward": "res://assets/audio/reward.mp3",
}

@export var control_mode: ControlMode = ControlMode.SCREEN_DIRECT

@export_group("Kecepatan & Akselerasi")
@export var max_speed: float = 23.0
@export var acceleration: float = 20.0
@export var brake_force: float = 48.0
@export var reverse_max_speed: float = 9.5
@export var reverse_acceleration: float = 12.0
@export var handbrake_force: float = 75.0
@export var road_friction: float = 10.0

@export_group("Off-road & Rumput")
@export var grass_friction: float = 34.0
@export var grass_max_speed: float = 7.5

@export_group("Kemudi Presisi (Arcade Steering)")
@export var turn_speed: float = 7.5          # Kecepatan rotasi mobil menuju arah input (Screen Direct)
@export var classic_turn_speed: float = 3.0  # Kecepatan putar di mode klasik
@export var steer_sensitivity: float = 1.0

var current_speed: float = 0.0
var current_steer_val: float = 0.0
var impact_cooldown: float = 0.0

var is_braking_active: bool = false
var is_handbrake_active: bool = false
var is_offroad_active: bool = false

@onready var visual_root: Node3D = $CarMBGVisual
var wheel_fl: Node3D
var wheel_fr: Node3D
var taillight_l: MeshInstance3D
var taillight_r: MeshInstance3D
var exhaust_smoke: CPUParticles3D
var tire_dust_l: CPUParticles3D
var tire_dust_r: CPUParticles3D
var impact_sparks: CPUParticles3D
var vehicle_audio: Dictionary = {}
var was_braking: bool = false
var mission_complete_sound_pending: bool = false

var bump_offset_y: float = 0.0
var bump_pitch: float = 0.0

@export var is_player_controlling: bool = true

func _ready() -> void:
	add_to_group("player")
	add_to_group("player_car")
	_setup_vehicle_audio()
	
	# Konfigurasi penempelan lantai yang tenang dan bebas getar (Anti-Jitter)
	floor_snap_length = 0.3
	floor_constant_speed = true
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(45.0)
	
	# Pisahkan layer tabrakan mobil (Layer 2) agar tidak bentrok dengan pejalan kaki (Layer 4)
	collision_layer = 2
	collision_mask = 1
	
	# Sinkronisasi statistik aktif dari Driver & Armada Mobil terpilih di Main Menu
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("get_active_driver") and gm.has_method("get_active_vehicle"):
		var drv = gm.get_active_driver()
		var veh = gm.get_active_vehicle()
		var drv_spd: float = drv.get("speed_mult", 1.0)
		var drv_acc: float = drv.get("accel_mult", 1.0)
		var drv_steer: float = drv.get("steer_mult", 1.0)
		var veh_spd: float = veh.get("speed_mult", 1.0)
		var veh_acc: float = veh.get("accel_mult", 1.0)
		
		# Terapkan bonus dari Bengkel Upgrade Kendaraan
		var engine_bonus = 1.0 + (gm.vehicle_upgrades.get("engine", 0) * 0.10)
		var turbo_bonus = 1.0 + (gm.vehicle_upgrades.get("turbo", 0) * 0.15)
		var handling_bonus = 1.0 + (gm.vehicle_upgrades.get("handling", 0) * 0.15)

		max_speed *= (drv_spd * veh_spd * engine_bonus)
		acceleration *= (drv_acc * veh_acc * turbo_bonus)
		turn_speed *= (drv_steer * handling_bonus)
		print("[Car] Stats Aktif -> MaxSpeed: %.1f | Accel: %.1f | Steer: %.2f | Driver: %s | Mobil: %s" % [
			max_speed, acceleration, turn_speed, drv.get("name", "Driver"), veh.get("name", "Mobil")
		])

		# Lampu Sorot Depan (Headlights) untuk Season Malam
		var hl = Node3D.new()
		hl.name = "Headlights"
		var spot_l = SpotLight3D.new()
		spot_l.position = Vector3(-0.6, 0.6, 2.0)
		spot_l.spot_range = 28.0
		spot_l.spot_angle = 35.0
		spot_l.light_energy = 3.5
		spot_l.light_color = Color(1.0, 0.95, 0.8)
		hl.add_child(spot_l)
		var spot_r = SpotLight3D.new()
		spot_r.position = Vector3(0.6, 0.6, 2.0)
		spot_r.spot_range = 28.0
		spot_r.spot_angle = 35.0
		spot_r.light_energy = 3.5
		spot_r.light_color = Color(1.0, 0.95, 0.8)
		hl.add_child(spot_r)
		hl.visible = (gm.current_season == gm.Season.MALAM)
		add_child(hl)

	if visual_root:
		wheel_fl = visual_root.get_node_or_null("WheelFrontLeft")
		wheel_fr = visual_root.get_node_or_null("WheelFrontRight")
		taillight_l = visual_root.get_node_or_null("TaillightLeft") as MeshInstance3D
		taillight_r = visual_root.get_node_or_null("TaillightRight") as MeshInstance3D
		exhaust_smoke = visual_root.get_node_or_null("ExhaustPipe/ExhaustSmoke") as CPUParticles3D
		tire_dust_l = visual_root.get_node_or_null("TireDustLeft") as CPUParticles3D
		tire_dust_r = visual_root.get_node_or_null("TireDustRight") as CPUParticles3D
		impact_sparks = visual_root.get_node_or_null("ImpactSparks") as CPUParticles3D

		var driver_sprite = visual_root.get_node_or_null("DriverSprite") as Sprite3D
		if driver_sprite:
			driver_sprite.visible = false

func set_controlling(active: bool) -> void:
	var was_controlling := is_player_controlling
	is_player_controlling = active
	if not active:
		current_speed = 0.0
		current_steer_val = 0.0
		velocity = Vector3.ZERO
		_stop_engine_audio()
	elif not was_controlling:
		play_engine_start_sound()

func _setup_vehicle_audio() -> void:
	for sound_name in AUDIO_STREAM_PATHS:
		var stream_path: String = AUDIO_STREAM_PATHS[sound_name]
		var sound_stream := load(stream_path) as AudioStream
		if not sound_stream:
			push_error("Audio kendaraan gagal dimuat: %s" % stream_path)
			continue

		if sound_name == "engine_driving" and sound_stream is AudioStreamMP3:
			var mp3_stream := sound_stream as AudioStreamMP3
			mp3_stream.loop = true

		var audio_player := AudioStreamPlayer3D.new()
		audio_player.name = "%sAudio" % sound_name.capitalize()
		audio_player.stream = sound_stream
		audio_player.max_distance = 75.0
		audio_player.unit_size = 8.0
		add_child(audio_player)
		vehicle_audio[sound_name] = audio_player

	var reward_player := _get_audio_player("reward")
	if reward_player:
		reward_player.finished.connect(_play_pending_mission_complete_sound)

func _get_audio_player(sound_name: String) -> AudioStreamPlayer3D:
	return vehicle_audio.get(sound_name) as AudioStreamPlayer3D

func _play_vehicle_sound(sound_name: String) -> void:
	var audio_player := _get_audio_player(sound_name)
	if audio_player:
		audio_player.play()

func play_engine_start_sound() -> void:
	_play_vehicle_sound("engine_start")

func play_reward_sound() -> void:
	_play_vehicle_sound("reward")

func play_collision_sound() -> void:
	_play_vehicle_sound("collision")

func play_mission_complete_sound() -> void:
	var reward_player := _get_audio_player("reward")
	if reward_player and reward_player.playing:
		mission_complete_sound_pending = true
	else:
		_play_vehicle_sound("mission_complete")

func _play_pending_mission_complete_sound() -> void:
	if mission_complete_sound_pending:
		mission_complete_sound_pending = false
		_play_vehicle_sound("mission_complete")

func _stop_engine_audio() -> void:
	var engine_player := _get_audio_player("engine_driving")
	if engine_player and engine_player.playing:
		engine_player.stop()

func _update_vehicle_audio() -> void:
	var engine_player := _get_audio_player("engine_driving")
	var should_play_engine: bool = is_player_controlling and abs(current_speed) > 0.5
	if engine_player:
		if should_play_engine and not engine_player.playing:
			engine_player.play()
		elif not should_play_engine and engine_player.playing:
			engine_player.stop()

	var is_braking: bool = is_braking_active and abs(current_speed) > 1.0
	if is_braking and not was_braking:
		_play_vehicle_sound("brake")
	was_braking = is_braking

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Tombol H: Bunyikan Klakson Mobil (GDD Bab 7.1)
		if event.keycode == KEY_H and is_player_controlling:
			trigger_horn()
		# Tombol TAB: Tukar Mode Kendali (Arah Layar vs Simulator Klasik)
		if event.keycode == KEY_TAB and is_player_controlling:
			toggle_control_mode()

		# Pengaturan Sensitivitas Kemudi On-the-fly via Shortcut [ dan ]
		if is_player_controlling:
			if event.keycode == KEY_BRACKETLEFT:
				steer_sensitivity = clamp(steer_sensitivity - 0.1, 0.4, 2.2)
				print("[MBG] Sensitivitas Kemudi: ", snapped(steer_sensitivity, 0.1), "x")
			elif event.keycode == KEY_BRACKETRIGHT:
				steer_sensitivity = clamp(steer_sensitivity + 0.1, 0.4, 2.2)
				print("[MBG] Sensitivitas Kemudi: ", snapped(steer_sensitivity, 0.1), "x")

func trigger_horn() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_horn"):
		am.play_horn()

	# Efek Balon Suara 3D Melayang di atas mobil
	_spawn_horn_bubble()
	_show_hud_toast("📢 KLAKSON MBG: Jalanan terbuka untuk Pengawal Raja!")

func _spawn_horn_bubble() -> void:
	var bubble = Label3D.new()
	bubble.text = "📢 TIIIN TIIIN!"
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 28
	bubble.outline_size = 6
	bubble.outline_modulate = Color.BLACK
	bubble.modulate = Color(1.0, 0.9, 0.2)
	bubble.position = Vector3(0, 2.6, -0.6)
	add_child(bubble)

	var tween = create_tween()
	tween.tween_property(bubble, "position:y", 3.4, 0.8)
	tween.parallel().tween_property(bubble, "scale", Vector2(1.2, 1.2), 0.3)
	tween.parallel().tween_property(bubble, "modulate:a", 0.0, 0.8)
	tween.tween_callback(bubble.queue_free)

func toggle_control_mode() -> void:
	if control_mode == ControlMode.SCREEN_DIRECT:
		control_mode = ControlMode.CLASSIC_STEER
		_show_hud_toast("🏎️ Mode Kendali: Simulator Klasik (W=Gas, S=Rem/Mundur, A/D=Setir)")
	else:
		control_mode = ControlMode.SCREEN_DIRECT
		_show_hud_toast("🧭 Mode Kendali: Arah Layar (W=Atas, S=Bawah, A=Kiri, D=Kanan)")

func _show_hud_toast(msg: String) -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		var hud_node = get_node_or_null("../HUD")
		if hud_node and hud_node.has_method("show_toast"):
			hud_node.show_toast(msg, 3.0)
	elif hud.has_method("show_toast"):
		hud.show_toast(msg, 3.0)

func _physics_process(delta: float) -> void:
	if not is_player_controlling:
		# Saat pengemudi turun dari mobil: Mobil berhenti tenang tanpa getaran
		velocity.x = 0.0
		velocity.z = 0.0
		velocity.y = 0.0 if is_on_floor() else -9.8 * delta
		move_and_slide()
		return

	if impact_cooldown > 0.0:
		impact_cooldown -= delta

	# Deteksi Permukaan Jalan (Aspal vs Rumput)
	is_offroad_active = not _is_on_pavement(global_position)
	var top_speed = grass_max_speed if is_offroad_active else max_speed
	var eff_friction = grass_friction if is_offroad_active else road_friction

	var handbrake = Input.is_key_pressed(KEY_SPACE)
	is_handbrake_active = handbrake

	# Pembacaan Input WASD / Panah
	var fwd = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var back = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var left = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)

	if control_mode == ControlMode.SCREEN_DIRECT:
		_process_screen_direct_driving(fwd, back, left, right, handbrake, top_speed, eff_friction, delta)
	else:
		_process_classic_steer_driving(fwd, back, left, right, handbrake, top_speed, eff_friction, delta)

	# Konsumsi Bahan Bakar saat mobil berjalan (GDD Bab 5.4 & 10.2)
	if abs(current_speed) > 1.0:
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("consume_fuel"):
			var fuel_burn_rate = 0.035 * (abs(current_speed) / max_speed)
			gm.consume_fuel(fuel_burn_rate * delta)

	# Suspensi & Body Roll Halus
	bump_offset_y = lerp(bump_offset_y, 0.0, 1.0 - exp(-12.0 * delta))
	bump_pitch = lerp(bump_pitch, 0.0, 1.0 - exp(-14.0 * delta))

	if visual_root:
		var speed_ratio = clamp(abs(current_speed) / max_speed, 0.0, 1.0)
		var target_roll = -current_steer_val * 0.035 * speed_ratio
		var target_pitch = 0.0
		if is_braking_active or handbrake:
			target_pitch = deg_to_rad(1.8)
			
		visual_root.rotation.z = lerp(visual_root.rotation.z, target_roll, 1.0 - exp(-12.0 * delta))
		visual_root.rotation.x = lerp(visual_root.rotation.x, target_pitch + bump_pitch, 1.0 - exp(-14.0 * delta))
		visual_root.position.y = bump_offset_y

	# Partikel Knalpot
	if exhaust_smoke:
		var is_moving = abs(current_speed) > 0.5
		exhaust_smoke.speed_scale = 1.5 if is_moving else 0.7

	# Partikel Debu Ban (Skid / Rem Tangan / Off-road)
	var is_hard_skid = (is_braking_active and abs(current_speed) > 3.0) or (handbrake and abs(current_speed) > 1.5)
	var should_emit_dust = is_hard_skid or (is_offroad_active and abs(current_speed) > 2.5)
	if tire_dust_l and tire_dust_r:
		tire_dust_l.emitting = should_emit_dust
		tire_dust_r.emitting = should_emit_dust

	# Terapkan Gerak Fisika Tanpa Getaran Vertikal (Anti-Vibration Physics)
	var target_move = -transform.basis.z * current_speed
	velocity.x = lerp(velocity.x, target_move.x, 1.0 - exp(-24.0 * delta))
	velocity.z = lerp(velocity.z, target_move.z, 1.0 - exp(-24.0 * delta))
	
	if not is_on_floor():
		velocity.y -= 25.0 * delta
	else:
		velocity.y = 0.0 # NOL saat di lantai agar tidak ada osilasi getaran benturan
		
	move_and_slide()
	_update_vehicle_audio()

	# Deteksi Benturan Keras
	if impact_cooldown <= 0.0:
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			var collider = col.get_collider()
			if collider and (collider.is_in_group("ground") or "Ground" in collider.name or "Road" in collider.name):
				continue
			if col.get_normal().y > 0.3:
				continue
			if abs(current_speed) > 13.0:
				var gm = get_node_or_null("/root/GameManager")
				if gm and gm.has_method("apply_impact"):
					gm.apply_impact(abs(current_speed))
				trigger_impact_vfx()
				play_collision_sound()
				current_speed *= 0.5
				impact_cooldown = 1.5
				break

# ==============================================================================
# MODE 1: KENDALI SELARAS ARAH LAYAR (W=Atas, S=Bawah, A=Kiri, D=Kanan)
# ==============================================================================
func _process_screen_direct_driving(fwd: bool, back: bool, left: bool, right: bool, handbrake: bool, top_speed: float, eff_friction: float, delta: float) -> void:
	var move_input = Vector2.ZERO
	if right: move_input.x += 1.0
	if left: move_input.x -= 1.0
	if back: move_input.y += 1.0
	if fwd: move_input.y -= 1.0

	if handbrake:
		is_braking_active = true
		current_speed = move_toward(current_speed, 0.0, handbrake_force * delta)
		return

	if move_input.length() > 0.1:
		move_input = move_input.normalized()
		
		# Arah sasaran di dunia 3D selaras dengan pandangan layar isometrik:
		# D (kanan) -> +X (arah SDN 01)
		# A (kiri)  -> -X (arah SPPG)
		# W (atas)  -> -Z (arah Bundaran Utara)
		# S (bawah) -> +Z (arah Selatan)
		var target_dir = Vector3(move_input.x, 0.0, move_input.y).normalized()
		var target_rot_y = atan2(-target_dir.x, -target_dir.z)

		# Putar mobil dengan mulus dan mantap ke arah yang ditekan
		var effective_rot_rate = turn_speed * steer_sensitivity
		rotation.y = lerp_angle(rotation.y, target_rot_y, 1.0 - exp(-effective_rot_rate * delta))

		# Hitung sudut belok roda depan
		var angle_diff = wrapf(target_rot_y - rotation.y, -PI, PI)
		current_steer_val = clamp(angle_diff * 1.8, -1.0, 1.0)
		if wheel_fl and wheel_fr:
			var wheel_angle = clamp(angle_diff * 1.5, -deg_to_rad(30.0), deg_to_rad(30.0))
			wheel_fl.rotation.y = lerp_angle(wheel_fl.rotation.y, wheel_angle, 1.0 - exp(-20.0 * delta))
			wheel_fr.rotation.y = lerp_angle(wheel_fr.rotation.y, wheel_angle, 1.0 - exp(-20.0 * delta))

		# Akselerasi maju
		current_speed = move_toward(current_speed, top_speed, acceleration * delta)
		is_braking_active = false
	else:
		# Meluncur sampai berhenti
		current_speed = move_toward(current_speed, 0.0, eff_friction * delta)
		is_braking_active = false
		current_steer_val = lerp(current_steer_val, 0.0, 1.0 - exp(-16.0 * delta))
		if wheel_fl and wheel_fr:
			wheel_fl.rotation.y = lerp_angle(wheel_fl.rotation.y, 0.0, 1.0 - exp(-16.0 * delta))
			wheel_fr.rotation.y = lerp_angle(wheel_fr.rotation.y, 0.0, 1.0 - exp(-16.0 * delta))

# ==============================================================================
# MODE 2: KENDALI SIMULATOR KLASIK (W=Gas, S=Rem/Mundur, A=Kiri, D=Kanan)
# ==============================================================================
func _process_classic_steer_driving(fwd: bool, back: bool, left: bool, right: bool, handbrake: bool, top_speed: float, eff_friction: float, delta: float) -> void:
	if handbrake:
		is_braking_active = true
		current_speed = move_toward(current_speed, 0.0, handbrake_force * delta)
	elif fwd and not back:
		if current_speed < -0.3:
			is_braking_active = true
			current_speed = move_toward(current_speed, 0.0, brake_force * delta)
		else:
			is_braking_active = false
			current_speed = move_toward(current_speed, top_speed, acceleration * delta)
	elif back and not fwd:
		if current_speed > 0.3:
			is_braking_active = true
			current_speed = move_toward(current_speed, 0.0, brake_force * delta)
		else:
			is_braking_active = false
			var rev_limit = -min(reverse_max_speed, top_speed * 0.6)
			current_speed = move_toward(current_speed, rev_limit, reverse_acceleration * delta)
	else:
		is_braking_active = false
		current_speed = move_toward(current_speed, 0.0, eff_friction * delta)

	var target_steer: float = (1.0 if left else 0.0) - (1.0 if right else 0.0)
	var steer_rate = (8.5 * steer_sensitivity) if abs(target_steer) > 0.01 else 18.0
	current_steer_val = lerp(current_steer_val, target_steer, 1.0 - exp(-steer_rate * delta))
	if abs(target_steer) < 0.01 and abs(current_steer_val) < 0.015:
		current_steer_val = 0.0

	var speed_ratio = clamp(abs(current_speed) / max_speed, 0.0, 1.0)
	var speed_factor = lerp(1.2, 0.52, speed_ratio)
	if abs(current_speed) > 0.15:
		var dir = 1.0 if current_speed >= 0.0 else -1.0
		var effective_turn = current_steer_val * classic_turn_speed * steer_sensitivity * speed_factor
		rotate_y(effective_turn * delta * dir)

	if wheel_fl and wheel_fr:
		var wheel_angle = current_steer_val * deg_to_rad(28.0)
		wheel_fl.rotation.y = lerp_angle(wheel_fl.rotation.y, wheel_angle, 1.0 - exp(-20.0 * delta))
		wheel_fr.rotation.y = lerp_angle(wheel_fr.rotation.y, wheel_angle, 1.0 - exp(-20.0 * delta))

func _is_on_pavement(pos: Vector3) -> bool:
	var dist_center = Vector2(pos.x, pos.z).length()
	if dist_center <= 24.8:
		return true
	return abs(pos.z) <= 10.8 or abs(pos.x) <= 10.8

func trigger_impact_vfx() -> void:
	if impact_sparks:
		impact_sparks.restart()
	bump_offset_y = 0.25
	bump_pitch = deg_to_rad(-5.0)

func trigger_pothole_bump() -> void:
	bump_offset_y = 0.2
	bump_pitch = deg_to_rad(randf_range(-3.0, 3.0))
	if tire_dust_l:
		tire_dust_l.restart()
	if tire_dust_r:
		tire_dust_r.restart()
