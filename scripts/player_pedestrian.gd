extends CharacterBody3D

signal mode_changed(is_on_foot: bool)

@export var car_target: CharacterBody3D
@export var camera_node: Camera3D
@export var walk_speed: float = 5.2
@export var sprint_speed: float = 8.0
@export var enter_car_distance: float = 7.5

@onready var sprite: Sprite3D = $Sprite3D
@onready var prompt_label: Label3D = $PromptLabel
@onready var food_box_visual: Node3D = $FoodBoxVisual
@onready var shadow_disc: MeshInstance3D = $ShadowDisc
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_active: bool = false
var step_timer: float = 0.0

func _ready() -> void:
	add_to_group("pedestrian")
	
	visible = false
	is_active = false
	
	# Matikan tabrakan dan proses fisika saat di dalam mobil agar tidak menyebabkan mobil bergetar
	if collision_shape:
		collision_shape.disabled = true
	set_physics_process(false)
	
	_load_pedestrian_texture()
	
	if not car_target:
		car_target = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not camera_node:
		camera_node = get_viewport().get_camera_3d()

func _load_pedestrian_texture() -> void:
	var path = "res://assets/textures/characters/player_driver_standing.png"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img:
			tex = ImageTexture.create_from_image(img)
	if tex and sprite:
		sprite.texture = tex
		sprite.pixel_size = 0.0105
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.shaded = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			toggle_character_mode()

func toggle_character_mode() -> void:
	if is_active:
		# Jika sedang jalan kaki, cek apakah berada dalam jangkauan mobil untuk masuk kembali
		if car_target and global_position.distance_to(car_target.global_position) <= enter_car_distance:
			enter_car()
		else:
			# Cek interaksi zona serah terima SPPG atau Sekolah
			_check_zone_interaction()
	else:
		# Jika sedang di mobil, turun dari mobil
		if car_target:
			var car_speed = 0.0
			if "current_speed" in car_target:
				car_speed = abs(car_target.current_speed)
			if car_speed < 8.0:
				exit_car()

func exit_car() -> void:
	if not car_target:
		return
	is_active = true
	visible = true
	
	# Aktifkan kembali collider pejalan kaki
	if collision_shape:
		collision_shape.disabled = false
	set_physics_process(true)
	
	# Spawn di sisi pintu pengemudi (aman di samping badan mobil)
	var spawn_offset = -car_target.global_transform.basis.x * 2.5
	global_position = car_target.global_position + spawn_offset
	global_position.y = 0.25
	velocity = Vector3.ZERO
	
	# Nonaktifkan kontrol mobil
	if car_target.has_method("set_controlling"):
		car_target.set_controlling(false)
		
	# Kamera ganti target ke Rama pejalan kaki
	if camera_node and camera_node.has_method("set_target"):
		camera_node.set_target(self, 16.0)
		
	mode_changed.emit(true)
	print("[MBG] Petugas Rama turun dari mobil. Berjalan kaki aktif.")

func enter_car(force_warp: bool = false) -> void:
	if not car_target:
		return
		
	# Jika dipanggil via tombol HUD dari jarak agak jauh, izinkan masuk
	if not force_warp and global_position.distance_to(car_target.global_position) > enter_car_distance:
		return
		
	is_active = false
	visible = false
	velocity = Vector3.ZERO
	
	# Matikan collider agar tidak beradu dengan mobil
	if collision_shape:
		collision_shape.disabled = true
	set_physics_process(false)
	
	# Aktifkan kembali kontrol mobil
	if car_target.has_method("set_controlling"):
		car_target.set_controlling(true)
		
	# Kamera kembalikan target ke mobil
	if camera_node and camera_node.has_method("set_target"):
		camera_node.set_target(car_target, 24.0)
		
	mode_changed.emit(false)
	print("[MBG] Petugas Rama naik kembali ke mobil MBG.")

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	# Tampilkan kotak ransum jika sedang dalam fase mengantar
	var gm = get_node_or_null("/root/GameManager")
	if food_box_visual and gm:
		food_box_visual.visible = (gm.current_state == gm.State.DELIVERING)

	# Kontrol Jalan Kaki Selaras Layar (W=Atas, S=Bawah, A=Kiri, D=Kanan)
	var fwd = Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var back = Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)
	var left = Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
	var right = Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
	var is_sprint = Input.is_key_pressed(KEY_SHIFT)

	var move_input = Vector2.ZERO
	if right: move_input.x += 1.0
	if left: move_input.x -= 1.0
	if back: move_input.y += 1.0
	if fwd: move_input.y -= 1.0
	move_input = move_input.normalized()

	var speed = sprint_speed if is_sprint else walk_speed

	# Arah gerak selaras dengan layar (W = -Z / Atas, S = +Z / Bawah, A = -X / Kiri, D = +X / Kanan)
	if move_input.length() > 0.01:
		velocity.x = move_input.x * speed
		velocity.z = move_input.y * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 12.0 * delta)

	velocity.y = -9.8 * delta if not is_on_floor() else 0.0
	move_and_slide()

	# Animasi melangkah kaki
	var move_len = Vector2(velocity.x, velocity.z).length()
	if move_len > 0.2:
		step_timer += delta * (speed * 2.4)
		if sprite:
			sprite.position.y = 0.88 + abs(sin(step_timer)) * 0.08
			sprite.rotation.z = sin(step_timer) * deg_to_rad(6.0)
			if move_input.x < -0.1:
				sprite.flip_h = true
			elif move_input.x > 0.1:
				sprite.flip_h = false
	else:
		step_timer = 0.0
		if sprite:
			sprite.position.y = lerp(sprite.position.y, 0.88, 10.0 * delta)
			sprite.rotation.z = lerp(sprite.rotation.z, 0.0, 10.0 * delta)

	# Update prompt mengambang
	_update_prompt_label()

func _update_prompt_label() -> void:
	if not prompt_label:
		return
		
	if car_target and global_position.distance_to(car_target.global_position) <= enter_car_distance:
		prompt_label.text = "🚗 [Tekan E]: Masuk Mobil"
		prompt_label.modulate = Color(0.2, 0.95, 0.4, 1.0)
		prompt_label.visible = true
	else:
		prompt_label.visible = false

func _check_zone_interaction() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return
	if gm.current_state == gm.State.AT_SPPG:
		var sppg_pos = Vector3(-50, 0.15, -2)
		if global_position.distance_to(sppg_pos) < 7.0:
			gm.start_delivery()
	elif gm.current_state == gm.State.DELIVERING:
		var school_pos = Vector3(52, 0.15, -2)
		if global_position.distance_to(school_pos) < 7.0:
			gm.reach_school()
