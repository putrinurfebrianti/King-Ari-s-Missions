extends Node3D

@export var sun_light: DirectionalLight3D
@export var rain_particles: CPUParticles3D
@export var target_follow: Node3D

func _ready() -> void:
	if not target_follow:
		target_follow = get_tree().get_first_node_in_group("player") as Node3D
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_signal("season_changed"):
		gm.season_changed.connect(_on_season_changed)
		_update_weather(gm.current_season)

func _process(_delta: float) -> void:
	if rain_particles and target_follow:
		rain_particles.global_position.x = target_follow.global_position.x
		rain_particles.global_position.z = target_follow.global_position.z

func _on_season_changed(season_int: int) -> void:
	_update_weather(season_int)

func _update_weather(season_int: int) -> void:
	var is_rain = (season_int == 1) # Season.HUJAN
	if rain_particles:
		rain_particles.emitting = is_rain
		rain_particles.visible = is_rain
	if sun_light:
		if is_rain:
			sun_light.light_energy = 0.75
			sun_light.light_color = Color(0.78, 0.82, 0.88, 1.0)
		else:
			sun_light.light_energy = 1.2
			sun_light.light_color = Color(1.0, 0.98, 0.94, 1.0)
