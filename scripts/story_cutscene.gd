extends Control

const KING_ARI_IMAGE_PATH := "res://assets/textures/characters/king_ari_command.png"

@onready var bg_rect: TextureRect = $Background
@onready var speaker_label: Label = $DialogueBox/SpeakerLabel
@onready var dialogue_label: Label = $DialogueBox/ContentLabel
@onready var next_button: Button = $DialogueBox/NextButton
@onready var skip_button: Button = $SkipButton

@onready var ari_portrait: TextureRect = $Portraits/AriPortrait
@onready var driver_portrait: TextureRect = $Portraits/DriverPortrait
@onready var driver_name_tag: Label = $Portraits/DriverPortrait/NameTag

var dialogues: Array[Dictionary] = []
var current_step: int = 0
var typing_tween: Tween
var ari_command_tween: Tween
var active_driver: Dictionary = {}
var ari_resting_x: float = 0.0

func _ready() -> void:
	active_driver = GameManager.get_active_driver()
	
	_setup_portraits()
	if ari_portrait:
		ari_resting_x = ari_portrait.position.x
	_setup_dialogues()
	_start_ari_idle_animation()
	
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if skip_button:
		skip_button.pressed.connect(_start_gameplay)
		
	_display_current_step()

func _setup_portraits() -> void:
	if ari_portrait:
		var king_portrait := load(KING_ARI_IMAGE_PATH) as Texture2D
		if not king_portrait:
			push_error("Could not load King Ari portrait: " + KING_ARI_IMAGE_PATH)
		else:
			ari_portrait.texture = king_portrait
		
	# Load Driver yang dipilih
	var drv_path = active_driver.get("full_portrait_path", active_driver.get("portrait_path", ""))
	if ResourceLoader.exists(drv_path) and driver_portrait:
		driver_portrait.texture = load(drv_path) as Texture2D
		
	if driver_name_tag:
		driver_name_tag.text = active_driver.get("name", "Driver MBG")

func _start_ari_idle_animation() -> void:
	if not ari_portrait:
		return

	var resting_y := ari_portrait.position.y
	var idle_tween := create_tween().set_loops()
	idle_tween.tween_property(ari_portrait, "position:y", resting_y - 2.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(ari_portrait, "position:y", resting_y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_ari_command_animation() -> void:
	if not ari_portrait:
		return

	_stop_ari_command_animation()
	var resting_x := ari_resting_x
	ari_command_tween = create_tween().set_loops()
	ari_command_tween.tween_property(ari_portrait, "position:x", resting_x + 3.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ari_command_tween.parallel().tween_property(ari_portrait, "rotation_degrees", 1.5, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ari_command_tween.tween_interval(0.42)
	ari_command_tween.tween_property(ari_portrait, "position:x", resting_x, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ari_command_tween.parallel().tween_property(ari_portrait, "rotation_degrees", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ari_command_tween.tween_interval(0.25)
	ari_command_tween.tween_property(ari_portrait, "position:x", resting_x - 2.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ari_command_tween.parallel().tween_property(ari_portrait, "rotation_degrees", -1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ari_command_tween.tween_interval(0.35)
	ari_command_tween.tween_property(ari_portrait, "position:x", resting_x, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ari_command_tween.parallel().tween_property(ari_portrait, "rotation_degrees", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_ari_command_animation() -> void:
	if ari_command_tween and ari_command_tween.is_running():
		ari_command_tween.kill()
	if ari_portrait:
		ari_portrait.position.x = ari_resting_x
		ari_portrait.rotation_degrees = 0.0

func _setup_dialogues() -> void:
	var drv_name = active_driver.get("name", "Pengawal")
	dialogues = [
		{
			"speaker": "📜 TITAH RAJA ARI: MISI PERDANA GENERASI EMAS",
			"text": "Di sebuah negara kepulauan berkembang bernama Tenjo Island... Raja Ari memiliki cita-cita agung: membangun Generasi Emas yang sehat, cerdas, dan siap memimpin masa depan melalui Makan Bergizi Gratis (MBG)!",
			"focus": "both"
		},
		{
			"speaker": "👑 Raja Ari (Pemimpin Tenjo Island)",
			"text": "Wahai pengawal kepercayaanku, " + drv_name + "! Hari ini adalah Titah Pertama Kerajaan! Kamu bersama trio pengawal Fatur, Mahdi, dan Zen memikul amanah penting untuk mendistribusikan MBG ke 5 SEKOLAH sebelum bel berbunyi!",
			"focus": "ari"
		},
		{
			"speaker": "👑 Raja Ari (Pemimpin Tenjo Island)",
			"text": "Laporan dari lapangan: jalanan selatan sedang terblokade oleh aksi demonstrasi warga, dan ada titik jalan amblas berlubang! Kalian harus cerdas memilih rute alternatif, menjaga tangki bahan bakar (40 Liter), serta singgah di SPBU jika bensin menipis!",
			"focus": "ari"
		},
		{
			"speaker": "👑 Raja Ari (Pemimpin Tenjo Island)",
			"text": "Batas waktu misi ini adalah 5 MENIT (05:00)! Untuk setiap sekolah yang sukses menerima makanan, guru akan memberikan upah 5 Koin Perak! Jaga kondisi makanan di atas 80% demi kehormatan kerajaan!",
			"focus": "ari"
		},
		{
			"speaker": "🎖️ " + drv_name + " (Pengawal Raja Ari)",
			"text": "Titah Paduka Raja kami junjung tinggi! Seluruh 5 sekolah di Tenjo Island akan menerima ransum MBG dengan higienis dan tepat waktu. Kami siap berangkat ke dapur SPPG sekarang!",
			"focus": "driver"
		}
	]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_next_pressed()
		elif event.keycode == KEY_ESCAPE:
			_start_gameplay()

func _on_next_pressed() -> void:
	if typing_tween and typing_tween.is_running():
		# Jika teks masih mengetik, percepat langsung tampil penuh
		typing_tween.kill()
		dialogue_label.visible_ratio = 1.0
		return
		
	current_step += 1
	if current_step < dialogues.size():
		_display_current_step()
	else:
		_start_gameplay()

func _display_current_step() -> void:
	var d = dialogues[current_step]
	speaker_label.text = d["speaker"]
	dialogue_label.text = d["text"]
	dialogue_label.visible_ratio = 0.0
	
	# Efek fokus potret karakter
	var focus = d.get("focus", "both")
	if focus == "ari":
		_start_ari_command_animation()
	else:
		_stop_ari_command_animation()
	if ari_portrait and driver_portrait:
		if focus == "ari":
			ari_portrait.modulate = Color.WHITE
			driver_portrait.modulate = Color(0.5, 0.5, 0.55, 0.8)
			ari_portrait.scale = Vector2(1.05, 1.05)
			driver_portrait.scale = Vector2(0.95, 0.95)
		elif focus == "driver":
			ari_portrait.modulate = Color(0.5, 0.5, 0.55, 0.8)
			driver_portrait.modulate = Color.WHITE
			ari_portrait.scale = Vector2(0.95, 0.95)
			driver_portrait.scale = Vector2(1.05, 1.05)
		else:
			ari_portrait.modulate = Color.WHITE
			driver_portrait.modulate = Color.WHITE
			ari_portrait.scale = Vector2.ONE
			driver_portrait.scale = Vector2.ONE
	
	# Typewriter Animation
	if typing_tween:
		typing_tween.kill()
	typing_tween = create_tween()
	var duration = clamp(d["text"].length() * 0.025, 0.8, 2.5)
	typing_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	
	if current_step == dialogues.size() - 1:
		next_button.text = "Tancap Gas! 🚀"
	else:
		next_button.text = "Lanjut ▶"

func _start_gameplay() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
