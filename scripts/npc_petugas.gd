extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var speech_pivot: Node3D = $SpeechPivot
@onready var speech_label: Label3D = $SpeechPivot/SpeechLabel

func _ready() -> void:
	if anim_player and anim_player.has_animation("idle_wave"):
		anim_player.play("idle_wave")
	
	if speech_label:
		speech_label.text = "Ransum Siap! 🍱"
		speech_label.modulate = Color(0.1, 0.85, 0.45, 1.0)
	
	if GameManager:
		GameManager.food_changed.connect(_on_food_changed)

func _process(_delta: float) -> void:
	# Buat teks speech bubble selalu menghadap ke kamera
	if speech_pivot:
		var cam = get_viewport().get_camera_3d()
		if cam:
			speech_pivot.look_at(cam.global_position, Vector3.UP)
			speech_pivot.rotation.x = 0
			speech_pivot.rotation.z = 0

func _on_food_changed(current_food: float) -> void:
	if current_food >= 99.0 and speech_label:
		say_dialog("Hati-hati di jalan! Antar sebelum jam 12!", 3.5)

func say_dialog(text: String, duration: float = 3.0) -> void:
	if not speech_label:
		return
	speech_label.text = text
	speech_label.visible = true
	var tween = create_tween()
	tween.tween_property(speech_label, "scale", Vector3(1.2, 1.2, 1.2), 0.15)
	tween.tween_property(speech_label, "scale", Vector3(1.0, 1.0, 1.0), 0.15)
	await get_tree().create_timer(duration).timeout
	if speech_label:
		speech_label.text = "Ransum Siap! 🍱"
