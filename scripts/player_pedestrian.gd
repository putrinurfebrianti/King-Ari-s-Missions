extends CharacterBody3D

signal mode_changed(is_on_foot: bool)

const MAHDI_ANIMATION_FRAMES := {
	"walk_front": [
		Rect2(0, 0, 380, 768),
		Rect2(380, 0, 380, 768),
		Rect2(760, 0, 380, 768),
		Rect2(1140, 0, 380, 768)
	],
	"walk_side_right": [
		Rect2(1520, 0, 380, 768),
		Rect2(1900, 0, 380, 768),
		Rect2(2280, 0, 380, 768),
		Rect2(2660, 0, 380, 768)
	],
	"walk_side_left": [
		Rect2(3040, 0, 380, 768),
		Rect2(3420, 0, 380, 768),
		Rect2(3800, 0, 380, 768),
		Rect2(4180, 0, 380, 768)
	],
	"walk_back": [
		Rect2(4560, 0, 380, 768),
		Rect2(4940, 0, 380, 768),
		Rect2(5320, 0, 380, 768),
		Rect2(5700, 0, 380, 768)
	]
}

const FATUR_DIRECTION_FRAMES := {
	"walk_front": [
		Rect2(0, 0, 380, 768),
		Rect2(380, 0, 380, 768),
		Rect2(760, 0, 380, 768),
		Rect2(1140, 0, 380, 768)
	],
	"walk_side_right": [
		Rect2(1520, 0, 380, 768),
		Rect2(1900, 0, 380, 768),
		Rect2(2280, 0, 380, 768),
		Rect2(2660, 0, 380, 768)
	],
	"walk_side_left": [
		Rect2(3040, 0, 380, 768),
		Rect2(3420, 0, 380, 768),
		Rect2(3800, 0, 380, 768),
		Rect2(4180, 0, 380, 768)
	],
	"walk_back": [
		Rect2(4560, 0, 380, 768),
		Rect2(4940, 0, 380, 768),
		Rect2(5320, 0, 380, 768),
		Rect2(5700, 0, 380, 768)
	]
}

const ZEN_DIRECTION_FRAMES := {
	"walk_front": [
		Rect2(0, 0, 380, 768),
		Rect2(380, 0, 380, 768),
		Rect2(760, 0, 380, 768),
		Rect2(1140, 0, 380, 768)
	],
	"walk_side_right": [
		Rect2(1520, 0, 380, 768),
		Rect2(1900, 0, 380, 768),
		Rect2(2280, 0, 380, 768),
		Rect2(2660, 0, 380, 768)
	],
	"walk_side_left": [
		Rect2(3040, 0, 380, 768),
		Rect2(3420, 0, 380, 768),
		Rect2(3800, 0, 380, 768),
		Rect2(4180, 0, 380, 768)
	],
	"walk_back": [
		Rect2(4560, 0, 380, 768),
		Rect2(4940, 0, 380, 768),
		Rect2(5320, 0, 380, 768),
		Rect2(5700, 0, 380, 768)
	]
}

@export var car_target: CharacterBody3D
@export var camera_node: Camera3D
@export var walk_speed: float = 5.2
@export var sprint_speed: float = 8.0
@export var enter_car_distance: float = 7.5

@onready var sprite: AnimatedSprite3D = $Sprite3D
@onready var prompt_label: Label3D = $PromptLabel
@onready var food_box_visual: Node3D = $FoodBoxVisual
@onready var shadow_disc: MeshInstance3D = $ShadowDisc
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_active: bool = false
var step_timer: float = 0.0
var sprite_resting_y: float = 0.88
var is_mahdi_pixel_character: bool = false
var is_fatur_pixel_character: bool = false
var is_zen_pixel_character: bool = false

func _ready() -> void:
	add_to_group("pedestrian")
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(50.0)
	
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
	var sprite_frames := SpriteFrames.new()
	sprite.pixel_size = 0.0105
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = false

	var gm = get_node_or_null("/root/GameManager")
	var driver_id: String = gm.selected_driver_id if gm else "fatur"

	if driver_id == "mahdi":
		is_mahdi_pixel_character = true
		_load_directional_pixel_character(
			"res://assets/textures/characters/driver_mahdi_pixel_views.png",
			MAHDI_ANIMATION_FRAMES
		)
		return

	if driver_id == "fatur":
		is_fatur_pixel_character = true
		_load_directional_pixel_character(
			"res://assets/textures/characters/driver_fatur_pixel_views.png",
			FATUR_DIRECTION_FRAMES
		)
		return

	if driver_id == "zen":
		is_zen_pixel_character = true
		_load_directional_pixel_character(
			"res://assets/textures/characters/driver_zen_pixel_views.png",
			ZEN_DIRECTION_FRAMES
		)
		return

	var path = "res://assets/textures/characters/player_driver_standing.png"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img:
			tex = ImageTexture.create_from_image(img)
	if tex and sprite:
		sprite_frames.add_frame("default", tex)
		sprite.sprite_frames = sprite_frames

func _load_directional_pixel_character(sheet_path: String, direction_frames: Dictionary) -> void:
	var sprite_sheet := load(sheet_path) as Texture2D
	if not sprite_sheet:
		push_error("Could not load directional pixel-art character: " + sheet_path)
		return

	var sprite_frames := SpriteFrames.new()
	sprite.pixel_size = 1.65 / 768.0
	sprite_resting_y = 0.85
	sprite.position.y = sprite_resting_y
	for animation_name in direction_frames:
		sprite_frames.add_animation(animation_name)
		sprite_frames.set_animation_speed(animation_name, 8.0)
		sprite_frames.set_animation_loop(animation_name, true)
		for region in direction_frames[animation_name]:
			var frame_texture := AtlasTexture.new()
			frame_texture.atlas = sprite_sheet
			frame_texture.region = region
			sprite_frames.add_frame(animation_name, frame_texture)
	sprite.sprite_frames = sprite_frames
	sprite.animation = "walk_front"
	sprite.stop()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			toggle_character_mode()
			get_viewport().set_input_as_handled()

func toggle_character_mode() -> void:
	if is_active:
		# Tombol E hanya digunakan untuk masuk kembali ke mobil.
		if car_target and global_position.distance_to(car_target.global_position) <= enter_car_distance:
			enter_car()
	else:
		# Jika sedang di mobil, turun dari mobil
		if car_target:
			var car_speed = 0.0
			if "current_speed" in car_target:
				car_speed = abs(car_target.current_speed)
			if car_speed < 8.0:
				exit_car()

func exit_car() -> void:
	if not car_target or is_active:
		return

	var car_speed: float = 0.0
	if "current_speed" in car_target:
		car_speed = abs(car_target.current_speed)
	if car_speed >= 8.0:
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
		
	# Kamera mengikuti pengawal saat berjalan kaki
	if camera_node and camera_node.has_method("set_target"):
		camera_node.set_target(self, 16.0)
		
	mode_changed.emit(true)
	print("[MBG] Pengawal turun dari mobil. Berjalan kaki aktif.")

func enter_car(force_warp: bool = false) -> void:
	if not car_target or not is_active:
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
	print("[MBG] Pengawal naik kembali ke mobil MBG.")

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

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= 24.0 * delta
	move_and_slide()
	var actual_velocity := get_real_velocity()
	var is_animating := Vector2(actual_velocity.x, actual_velocity.z).length() > 0.2
	if is_animating:
		if is_mahdi_pixel_character or is_fatur_pixel_character or is_zen_pixel_character:
			_update_pixel_character_animation(move_input)
			if is_fatur_pixel_character or is_zen_pixel_character or is_mahdi_pixel_character:
				step_timer += delta * (speed * 2.4)
				sprite.position.y = sprite_resting_y + abs(sin(step_timer)) * 0.035
		else:
			step_timer += delta * (speed * 2.4)
			sprite.position.y = sprite_resting_y + abs(sin(step_timer)) * 0.08
			sprite.rotation.z = sin(step_timer) * deg_to_rad(6.0)
			if move_input.x < -0.1:
				sprite.flip_h = true
			elif move_input.x > 0.1:
				sprite.flip_h = false
	else:
		step_timer = 0.0
		if is_mahdi_pixel_character or is_fatur_pixel_character or is_zen_pixel_character:
			sprite.stop()
			sprite.frame = 0
			sprite.position.y = lerp(sprite.position.y, sprite_resting_y, 10.0 * delta)
		else:
			sprite.position.y = lerp(sprite.position.y, sprite_resting_y, 10.0 * delta)
			sprite.rotation.z = lerp(sprite.rotation.z, 0.0, 10.0 * delta)

	# Update prompt mengambang
	_update_prompt_label()

func _update_pixel_character_animation(move_input: Vector2) -> void:
	var animation_name: String
	if abs(move_input.x) > abs(move_input.y):
		if is_fatur_pixel_character or is_zen_pixel_character:
			animation_name = "walk_side_right" if move_input.x > 0.0 else "walk_side_left"
			sprite.flip_h = false
		else:
			animation_name = "walk_side_right"
			sprite.flip_h = move_input.x < 0.0
	else:
		animation_name = "walk_back" if move_input.y < 0.0 else "walk_front"
		sprite.flip_h = false
	if sprite.animation != animation_name or not sprite.is_playing():
		sprite.play(animation_name)

func _update_prompt_label() -> void:
	if not prompt_label:
		return
		
	if car_target and global_position.distance_to(car_target.global_position) <= enter_car_distance:
		prompt_label.text = "🚗 [Tekan E]: Masuk Mobil"
		prompt_label.modulate = Color(0.2, 0.95, 0.4, 1.0)
		prompt_label.visible = true
	else:
		prompt_label.visible = false
