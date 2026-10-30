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
	if rain_particles and target_follow and is_instance_valid(target_follow):
		rain_particles.global_position.x = target_follow.global_position.x
		rain_particles.global_position.z = target_follow.global_position.z

func _on_season_changed(season_int: int) -> void:
	_update_weather(season_int)

func _update_weather(season_int: int) -> void:
	var is_rain = (season_int == 1) # Season.HUJAN
	var is_night = (season_int == 2) # Season.MALAM

	if rain_particles:
		rain_particles.emitting = is_rain
		rain_particles.visible = is_rain

	if sun_light:
		sun_light.light_energy = 0.95
		sun_light.light_color = Color(0.96, 0.93, 0.84, 1.0)

	# Update lampu jalanan dan kuburan
	var lamps = get_tree().get_nodes_in_group("street_lamps")
	for lamp in lamps:
		var light = lamp.get_node_or_null("OmniLight3D") as OmniLight3D
		if light:
			light.visible = is_night
			light.light_energy = 2.5 if is_night else 0.0

	# Update kuburan keramat (Graveyard) di season malam
	var grave = get_node_or_null("../GraveyardArea")
	if grave:
		var g_light1 = grave.get_node_or_null("EerieLantern1/OmniLightGreen1") as OmniLight3D
		var g_light2 = grave.get_node_or_null("EerieLantern2/OmniLightGreen2") as OmniLight3D
		if g_light1:
			g_light1.light_energy = 3.5 if is_night else 0.6
		if g_light2:
			g_light2.light_energy = 3.5 if is_night else 0.6

	# Update lampu depan mobil (Headlights)
	var car = get_tree().get_first_node_in_group("player") as Node3D
	if car and car.has_node("Headlights"):
		var hl = car.get_node("Headlights") as Node3D
		hl.visible = is_night
