extends Node3D

@export var texture_path: String = ""
@export var pixel_size: float = 0.012
@export var sprite_y_offset: float = 0.85
@export var bob_amplitude: float = 0.03
@export var bob_speed: float = 3.5
@export var character_name: String = ""
@export var dialog_text: String = ""
@export var speech_lines: Array[String] = []

# Fitur Patroli & Bergerak (Walker NPC)
@export var is_walker: bool = false
@export var walk_speed: float = 2.2
@export var patrol_waypoints: Array[Vector3] = []
@export var wait_duration: float = 2.5
@export var interaction_radius: float = 5.0

var initial_y: float = 0.0
var time_passed: float = 0.0
var walk_step_timer: float = 0.0
var wait_timer: float = 0.0
var current_waypoint_idx: int = 0
var is_waiting: bool = false

var sprite: Sprite3D
var shadow: MeshInstance3D
var speech_bubble: Label3D
var bubble_scale: float = 0.0

func _ready() -> void:
	initial_y = position.y
	time_passed = randf() * 6.28
	
	sprite = get_node_or_null("Sprite3D")
	if not sprite:
		sprite = Sprite3D.new()
		sprite.name = "Sprite3D"
		add_child(sprite)
	
	if not texture_path.is_empty():
		_load_character_texture()
		
	# Tambahkan bayangan di bawah kaki
	_setup_shadow()
	
	# Tambahkan Speech Bubble interaktif
	_setup_speech_bubble()
	
	# Inisialisasi waypoint pertama jika walker
	if is_walker and patrol_waypoints.size() > 0:
		current_waypoint_idx = 0
		wait_timer = randf_range(0.5, 2.0)

func _setup_shadow() -> void:
	shadow = MeshInstance3D.new()
	shadow.name = "ShadowDisc"
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.35
	cyl.height = 0.02
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.05, 0.08, 0.12, 0.45)
	cyl.material = mat
	shadow.mesh = cyl
	shadow.position = Vector3(0, 0.02, 0)
	add_child(shadow)

func _setup_speech_bubble() -> void:
	speech_bubble = Label3D.new()
	speech_bubble.name = "SpeechBubble"
	speech_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	speech_bubble.position = Vector3(0, 2.15, 0)
	speech_bubble.font_size = 17
	speech_bubble.outline_size = 4
	speech_bubble.outline_modulate = Color(0.04, 0.06, 0.1, 1.0)
	speech_bubble.modulate = Color(1.0, 0.95, 0.8, 1.0)
	speech_bubble.scale = Vector3.ZERO
	speech_bubble.visible = false
	
	if dialog_text.is_empty() and speech_lines.size() > 0:
		dialog_text = speech_lines[0]
		
	speech_bubble.text = "💬 " + dialog_text
	add_child(speech_bubble)

func _load_character_texture() -> void:
	var tex: Texture2D = null
	if ResourceLoader.exists(texture_path):
		tex = load(texture_path) as Texture2D
	
	if not tex:
		var path_to_load = texture_path
		if not FileAccess.file_exists(path_to_load):
			path_to_load = ProjectSettings.globalize_path(texture_path)
		if FileAccess.file_exists(path_to_load):
			var img = Image.load_from_file(path_to_load)
			if img:
				tex = ImageTexture.create_from_image(img)
	
	if tex:
		sprite.texture = tex
		sprite.pixel_size = pixel_size
		sprite.position.y = sprite_y_offset
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.shaded = false

func _process(delta: float) -> void:
	time_passed += delta * bob_speed
	
	# 1. Logika Pergerakan & Patroli
	if is_walker and patrol_waypoints.size() > 0:
		_process_walking(delta)
	else:
		# Idle breathing bobbing statis
		sprite.position.y = sprite_y_offset + sin(time_passed) * bob_amplitude
		sprite.rotation.z = lerp(sprite.rotation.z, 0.0, 8.0 * delta)
		
	# 2. Logika Interaksi & Speech Bubble
	_process_interaction(delta)

func _process_walking(delta: float) -> void:
	if is_waiting:
		wait_timer -= delta
		# Breathing bob saat berhenti
		sprite.position.y = sprite_y_offset + sin(time_passed) * (bob_amplitude * 0.7)
		sprite.rotation.z = lerp(sprite.rotation.z, 0.0, 8.0 * delta)
		if wait_timer <= 0.0:
			is_waiting = false
			current_waypoint_idx = (current_waypoint_idx + 1) % patrol_waypoints.size()
		return
		
	var target = patrol_waypoints[current_waypoint_idx]
	var cur_pos_2d = Vector2(global_position.x, global_position.z)
	var target_2d = Vector2(target.x, target.z)
	var dist = cur_pos_2d.distance_to(target_2d)
	
	if dist < 0.25:
		is_waiting = true
		wait_timer = wait_duration
		return
		
	# Gerak menuju target
	var move_dir = (target - global_position).normalized()
	global_position += move_dir * walk_speed * delta
	global_position.y = target.y
	
	# Flip sprite sesuai arah jalan
	if move_dir.x < -0.05:
		sprite.flip_h = true
	elif move_dir.x > 0.05:
		sprite.flip_h = false
		
	# Animasi melangkah (stride bounce & wobble)
	walk_step_timer += delta * (walk_speed * 4.5)
	var step_bounce = abs(sin(walk_step_timer)) * 0.075
	sprite.position.y = sprite_y_offset + step_bounce
	sprite.rotation.z = sin(walk_step_timer) * deg_to_rad(4.5)

func _process_interaction(delta: float) -> void:
	if not speech_bubble or dialog_text.is_empty():
		return
		
	# Cari player terdekat (mobil atau pejalan kaki)
	var players = get_tree().get_nodes_in_group("player")
	var min_dist = 9999.0
	for p in players:
		if p is Node3D and p.is_inside_tree() and p.visible:
			var d = global_position.distance_to(p.global_position)
			if d < min_dist:
				min_dist = d
				
	var should_show = min_dist <= interaction_radius
	var target_scale = 1.0 if should_show else 0.0
	bubble_scale = lerp(bubble_scale, target_scale, 10.0 * delta)
	
	if bubble_scale > 0.05:
		speech_bubble.visible = true
		speech_bubble.scale = Vector3.ONE * bubble_scale
	else:
		speech_bubble.visible = false
