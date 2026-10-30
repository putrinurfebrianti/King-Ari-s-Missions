extends Node

var master_volume: float = 0.8
var sfx_volume: float = 0.7
var is_muted: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioServer.set_bus_mute(0, is_muted)

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_update_vehicle_audio()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_update_vehicle_audio()

func set_muted(muted: bool) -> void:
	is_muted = muted
	AudioServer.set_bus_mute(0, is_muted)
	_update_vehicle_audio()

func get_vehicle_audio_volume_db() -> float:
	var volume := master_volume * sfx_volume
	if is_muted or volume <= 0.0:
		return -80.0
	return linear_to_db(volume)

func _update_vehicle_audio() -> void:
	for vehicle in get_tree().get_nodes_in_group("player_car"):
		if vehicle.has_method("apply_audio_settings"):
			vehicle.apply_audio_settings()
