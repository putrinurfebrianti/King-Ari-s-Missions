extends CanvasLayer

# Top Center Card (Timer & Navigasi)
@onready var timer_label: Label = get_node_or_null("TopCenterCard/TimerLabel")
@onready var nav_guide: Label = get_node_or_null("TopCenterCard/NavGuide")

# Left Dashboard (Profil Pengawal Raja & Statistik Misi)
@onready var left_dashboard: Panel = get_node_or_null("LeftDashboard")
@onready var driver_avatar: TextureRect = get_node_or_null("LeftDashboard/Avatar")
@onready var driver_name: Label = get_node_or_null("LeftDashboard/NameLabel")
@onready var driver_status: Label = get_node_or_null("LeftDashboard/StatusBadge")
@onready var food_label: Label = get_node_or_null("LeftDashboard/FoodLabel")
@onready var food_bar: ProgressBar = get_node_or_null("LeftDashboard/FoodBar")
@onready var steer_slider: HSlider = get_node_or_null("LeftDashboard/SteerSlider")
@onready var steer_val_label: Label = get_node_or_null("LeftDashboard/SteerValLabel")
@onready var walk_toggle_btn: Button = get_node_or_null("LeftDashboard/WalkToggleButton")

# Elemen Baru Sesuai GDD (Bahan Bakar, Sekolah Selesai, Musim)
var fuel_label: Label
var fuel_bar: ProgressBar
var schools_label: Label
var coins_label: Label
var season_btn: Button

# Toast Notification Banner
@onready var toast_banner: Panel = get_node_or_null("ToastBanner")
@onready var toast_label: Label = get_node_or_null("ToastBanner/ToastLabel")
var toast_tween: Tween

# Mission Result Modal
@onready var mission_modal: Panel = get_node_or_null("MissionModal")
@onready var modal_title: Label = get_node_or_null("MissionModal/TitleLabel")
@onready var modal_stars: Label = get_node_or_null("MissionModal/StarsLabel")
@onready var modal_detail: Label = get_node_or_null("MissionModal/DetailLabel")
@onready var modal_quote: Label = get_node_or_null("MissionModal/QuoteBox/QuoteLabel")
@onready var restart_button: Button = get_node_or_null("MissionModal/ButtonContainer/RestartButton")
@onready var menu_button: Button = get_node_or_null("MissionModal/ButtonContainer/MenuButton")

var player_car: CharacterBody3D
var player_pedestrian: CharacterBody3D

func _ready() -> void:
	# Hubungkan sinyal dari GameManager
	GameManager.food_changed.connect(_on_food_changed)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.fuel_changed.connect(_on_fuel_changed)
	GameManager.school_delivered.connect(_on_school_delivered)
	GameManager.delivery_started.connect(_on_delivery_started)
	GameManager.mission_completed.connect(_on_mission_completed)
	GameManager.mission_failed.connect(_on_mission_failed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.season_changed.connect(_on_season_changed)
	
	player_car = get_tree().get_first_node_in_group("player") as CharacterBody3D
	player_pedestrian = get_tree().get_first_node_in_group("pedestrian") as CharacterBody3D
	if player_pedestrian and player_pedestrian.has_signal("mode_changed"):
		player_pedestrian.mode_changed.connect(_on_mode_changed)

	_setup_extra_dashboard_ui()

	if walk_toggle_btn:
		walk_toggle_btn.pressed.connect(_on_walk_toggle_pressed)

	if steer_slider and player_car:
		steer_slider.value = player_car.steer_sensitivity
		steer_slider.value_changed.connect(_on_steer_slider_changed)
		_update_steer_label(player_car.steer_sensitivity)

	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
		
	if mission_modal:
		mission_modal.visible = false
	if toast_banner:
		toast_banner.visible = false
	
	# Profil Driver aktif
	var drv = GameManager.get_active_driver()
	if driver_name and drv:
		driver_name.text = drv.get("name", "Pengawal Raja")
	if driver_status and drv:
		driver_status.text = "● " + drv.get("title", "Pengawal Kepercayaan")
		
	if driver_avatar and drv:
		var path = drv.get("portrait_path", "")
		if path != "" and ResourceLoader.exists(path):
			driver_avatar.texture = load(path)
	
	if nav_guide:
		nav_guide.text = "➔ Rute: Muat Ransum MBG di Dapur SPPG (Zona Hijau)"
		
	_on_time_changed(GameManager.time_left)
	show_toast("👑 Titah Raja: Masuk ke SPPG untuk memuat MBG dan mulai pengiriman ke 5 Sekolah!", 4.5)

func _setup_extra_dashboard_ui() -> void:
	if not left_dashboard:
		return
	
	left_dashboard.custom_minimum_size = Vector2(250, 360)
	left_dashboard.size = Vector2(250, 360)

	# 1. Indikator Bahan Bakar (GDD Bab 5.4 & 10.2: 40 Liter)
	fuel_label = Label.new()
	fuel_label.text = "⛽ Bensin: 40.0 / 40.0 L"
	fuel_label.set_position(Vector2(14, 116))
	fuel_label.add_theme_font_size_override("font_size", 12)
	fuel_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	left_dashboard.add_child(fuel_label)

	fuel_bar = ProgressBar.new()
	fuel_bar.max_value = 40.0
	fuel_bar.value = 40.0
	fuel_bar.show_percentage = false
	fuel_bar.set_position(Vector2(14, 134))
	fuel_bar.set_size(Vector2(222, 10))
	left_dashboard.add_child(fuel_bar)

	# 2. Indikator Kemajuan 5 Sekolah
	schools_label = Label.new()
	schools_label.text = "🏫 Target: 0 / 5 Sekolah Selesai"
	schools_label.set_position(Vector2(14, 150))
	schools_label.add_theme_font_size_override("font_size", 12)
	schools_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	left_dashboard.add_child(schools_label)

	# 3. Koin Perak Kerajaan (+5 per sekolah)
	coins_label = Label.new()
	coins_label.text = "🪙 Kas: %d Koin (+5/sekolah)" % GameManager.coins
	coins_label.set_position(Vector2(14, 168))
	coins_label.add_theme_font_size_override("font_size", 12)
	coins_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	left_dashboard.add_child(coins_label)

	# Geser kontrol slider & tombol turun ke bawah agar rapi
	if steer_val_label:
		steer_val_label.set_position(Vector2(14, 190))
	if steer_slider:
		steer_slider.set_position(Vector2(14, 210))
	if walk_toggle_btn:
		walk_toggle_btn.set_position(Vector2(14, 240))
		walk_toggle_btn.set_size(Vector2(222, 34))

	# 4. Tombol Season (Musim Kemarau / Musim Hujan)
	season_btn = Button.new()
	season_btn.text = "☀️ Musim: Kemarau (Klik Ubah)"
	season_btn.set_position(Vector2(14, 282))
	season_btn.set_size(Vector2(222, 30))
	season_btn.add_theme_font_size_override("font_size", 11)
	season_btn.pressed.connect(_on_season_toggle_pressed)
	left_dashboard.add_child(season_btn)

func _on_season_toggle_pressed() -> void:
	GameManager.toggle_season()

func _on_season_changed(season_int: int) -> void:
	if season_btn:
		if season_int == GameManager.Season.HUJAN:
			season_btn.text = "🌧️ Musim: Hujan (Klik Ubah)"
			show_toast("🌧️ Cuaca berganti ke Musim Hujan! Jalanan lebih licin.", 3.0)
		else:
			season_btn.text = "☀️ Musim: Kemarau (Klik Ubah)"
			show_toast("☀️ Cuaca berganti ke Musim Kemarau! Jalanan kering.", 3.0)

func _process(_delta: float) -> void:
	if player_car and steer_slider and steer_slider.value != player_car.steer_sensitivity:
		steer_slider.value = player_car.steer_sensitivity
		_update_steer_label(player_car.steer_sensitivity)

func _on_steer_slider_changed(val: float) -> void:
	if player_car:
		player_car.steer_sensitivity = val
	_update_steer_label(val)

func _update_steer_label(val: float) -> void:
	if steer_val_label:
		steer_val_label.text = "Sensitivitas Setir: %.1fx" % val

func show_toast(msg: String, duration: float = 3.5) -> void:
	if not toast_banner or not toast_label:
		return
	toast_label.text = msg
	toast_banner.visible = true
	toast_banner.modulate.a = 1.0
	
	if toast_tween and toast_tween.is_running():
		toast_tween.kill()
		
	toast_tween = create_tween()
	toast_tween.tween_interval(duration)
	toast_tween.tween_property(toast_banner, "modulate:a", 0.0, 0.6)
	toast_tween.tween_callback(func(): toast_banner.visible = false)

func _on_delivery_started() -> void:
	if driver_status:
		driver_status.text = "● Mengantar Ransum (Sekolah 1/5)"
		driver_status.modulate = Color(0.25, 0.85, 1.0)
	if nav_guide:
		nav_guide.text = "➔ Rute: Menuju Sekolah 1/5: SDN 01 Tenjo"
	show_toast("🚚 MBG Dimuat! Raja Ari: 'Kawal makanan untuk Generasi Emas Tenjo!'", 4.0)

func _on_school_delivered(school_idx: int, school_name: String, delivered_count: int, total_count: int, earned_coins: int) -> void:
	if schools_label:
		schools_label.text = "🏫 Target: %d / %d Sekolah Selesai" % [delivered_count, total_count]
		schools_label.modulate = Color(0.3, 1.0, 0.5)
	if coins_label:
		coins_label.text = "🪙 Kas: %d Koin (+5/sekolah)" % GameManager.coins
		
	if delivered_count < total_count:
		var next_name = GameManager.schools_data[GameManager.current_school_idx]["name"]
		if nav_guide:
			nav_guide.text = "➔ Rute: Menuju Sekolah %d/%d: %s" % [GameManager.current_school_idx + 1, total_count, next_name]
		if driver_status:
			driver_status.text = "● Mengantar ke Sekolah %d/%d" % [GameManager.current_school_idx + 1, total_count]
		show_toast("🎉 %s Berhasil! Upah: +%d Koin. Lanjut ke %s!" % [school_name, earned_coins, next_name], 4.0)
	else:
		if nav_guide:
			nav_guide.text = "🎉 SELURUH 5 SEKOLAH SELESAI!"
		show_toast("🏆 SELURUH 5 SEKOLAH SUKSES MENERIMA MBG! (+%d Koin)" % earned_coins, 4.5)

func _on_food_changed(val: float) -> void:
	if food_label:
		food_label.text = "🍱 Kondisi Ransum: %d%%" % int(val)
		if val < 40.0:
			food_label.modulate = Color(1.0, 0.3, 0.3)
		elif val < 75.0:
			food_label.modulate = Color(1.0, 0.85, 0.2)
		else:
			food_label.modulate = Color(0.2, 0.95, 0.4)
			
	if food_bar:
		food_bar.value = val

func _on_fuel_changed(cur_fuel: float, max_f: float) -> void:
	if fuel_label:
		fuel_label.text = "⛽ Bensin: %.1f / %.1f L" % [cur_fuel, max_f]
		if cur_fuel < 10.0:
			fuel_label.modulate = Color(1.0, 0.25, 0.25)
		else:
			fuel_label.modulate = Color(0.3, 0.85, 1.0)
	if fuel_bar:
		fuel_bar.max_value = max_f
		fuel_bar.value = cur_fuel

func _on_coins_changed(new_coins: int) -> void:
	if coins_label:
		coins_label.text = "🪙 Kas: %d Koin (+5/sekolah)" % new_coins

func _on_time_changed(val: float) -> void:
	var mins = int(val / 60.0)
	var secs = int(val) % 60
	if timer_label:
		timer_label.text = "⏱️ Waktu: %02d:%02d" % [mins, secs]
		if val < 60.0:
			timer_label.modulate = Color(1.0, 0.3, 0.3)
		else:
			timer_label.modulate = Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_on_restart_pressed()

func _on_mission_completed(stars: int, score: int, earned_coins: int = 0) -> void:
	if driver_status:
		driver_status.text = "● Titah Raja Selesai Sempurna!"
		driver_status.modulate = Color(0.3, 1.0, 0.4)
		
	var drv = GameManager.get_active_driver()
	var drv_name: String = drv.get("name", "Pengawal")
	var king_quote = ""
	if stars == 3:
		king_quote = "👑 Raja Ari: 'Luar biasa, Pengawal %s! Seluruh 5 sekolah menerima makanan dengan kualitas sempurna! Generasi Emas Tenjo Island bangga padamu!'" % drv_name
	elif stars == 2:
		king_quote = "👑 Raja Ari: 'Kerja bagus, Pengawal %s. Seluruh anak sekolah telah menerima MBG tepat waktu sebelum bel berbunyi.'" % drv_name
	else:
		king_quote = "👑 Raja Ari: 'Misi selesai, namun makanan agak terguncang di jalan berlubang. Terus tingkatkan kehati-hatianmu, Pengawal!'"
		
	if modal_title:
		modal_title.text = "👑 TITAH RAJA ARI TUNTAS!"
		modal_title.modulate = Color.GOLD
	if modal_stars:
		modal_stars.text = "★".repeat(stars)
	if modal_detail:
		modal_detail.text = "5 Sekolah Selesai  |  Skor Pengantaran: %d  |  Upah Kerajaan: +%d Koin" % [score, earned_coins]
	if modal_quote:
		modal_quote.text = king_quote
	if mission_modal:
		mission_modal.visible = true

func _on_mission_failed(reason: String) -> void:
	if driver_status:
		driver_status.text = "● Misi Kerajaan Gagal"
		driver_status.modulate = Color(1.0, 0.35, 0.35)
	if modal_title:
		modal_title.text = "❌ MISI GAGAL"
		modal_title.modulate = Color(1.0, 0.35, 0.35)
	if modal_stars:
		modal_stars.text = "☆☆☆"
	if modal_detail:
		modal_detail.text = reason
	if modal_quote:
		modal_quote.text = "👑 Raja Ari: 'Anak-anak sekolah tidak menerima ransum gizi hari ini. Ulangi misi dari SPPG dan lakukan yang terbaik!'"
	if mission_modal:
		mission_modal.visible = true

func _on_restart_pressed() -> void:
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_walk_toggle_pressed() -> void:
	if player_pedestrian:
		if player_pedestrian.is_active:
			player_pedestrian.enter_car(true)
		else:
			player_pedestrian.exit_car()

func _on_mode_changed(is_on_foot: bool) -> void:
	if driver_status:
		if is_on_foot:
			driver_status.text = "● Mode: Pejalan Kaki (On-Foot)"
			driver_status.modulate = Color(1.0, 0.85, 0.2)
		else:
			driver_status.text = "● Mode: Mengemudi Van MBG"
			driver_status.modulate = Color(0.3, 0.95, 0.5)
	if walk_toggle_btn:
		walk_toggle_btn.text = "🚗 Naik Mobil (E)" if is_on_foot else "🚶 Turun Mobil (E)"
