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

# Elemen Tambahan Dashboard
var fuel_label: Label
var fuel_bar: ProgressBar
var schools_label: Label
var coins_label: Label
var season_btn: Button
var map_toggle_btn: Button

# Action Buttons
var bengkel_btn: Button
var perkakas_btn: Button
var panduan_btn: Button
var properti_btn: Button
var pov_cam_btn: Button

# Floating Prompt Interaksi SPBU & Rumah
var prompt_panel: Panel
var prompt_label: Label

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

# Dedicated Modals
var panduan_modal: Panel
var bengkel_modal: Panel
var perkakas_modal: Panel
var properti_modal: Panel

var player_car: CharacterBody3D
var player_pedestrian: CharacterBody3D

func _ready() -> void:
	add_to_group("hud")
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
	GameManager.house_purchased.connect(_on_house_purchased)
	GameManager.vehicle_upgraded.connect(_on_vehicle_upgraded)
	
	player_car = get_tree().get_first_node_in_group("player") as CharacterBody3D
	player_pedestrian = get_tree().get_first_node_in_group("pedestrian") as CharacterBody3D
	if player_pedestrian and player_pedestrian.has_signal("mode_changed"):
		player_pedestrian.mode_changed.connect(_on_mode_changed)

	_setup_extra_dashboard_ui()
	_setup_prompt_ui()
	_setup_modals()

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
	_on_season_changed(int(GameManager.current_season))

	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_signal("camera_mode_changed"):
		cam.camera_mode_changed.connect(_on_camera_mode_changed)

	show_toast("👑 Titah Raja: Masuk ke SPPG untuk memuat MBG dan mulai pengiriman ke 5 Sekolah!", 4.5)

func _setup_extra_dashboard_ui() -> void:
	if not left_dashboard:
		return
	
	left_dashboard.custom_minimum_size = Vector2(250, 510)
	left_dashboard.size = Vector2(250, 510)

	# 1. Indikator Bahan Bakar (GDD Bab 5.4 & 10.2: 40 Liter)
	fuel_label = Label.new()
	fuel_label.text = "⛽ Bensin: %.1f / %.1f L" % [GameManager.current_fuel, GameManager.max_fuel]
	fuel_label.set_position(Vector2(14, 116))
	fuel_label.add_theme_font_size_override("font_size", 12)
	fuel_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	left_dashboard.add_child(fuel_label)

	fuel_bar = ProgressBar.new()
	fuel_bar.max_value = GameManager.max_fuel
	fuel_bar.value = GameManager.current_fuel
	fuel_bar.show_percentage = false
	fuel_bar.set_position(Vector2(14, 134))
	fuel_bar.set_size(Vector2(222, 10))
	left_dashboard.add_child(fuel_bar)

	# 2. Indikator Kemajuan 5 Sekolah
	schools_label = Label.new()
	schools_label.text = "🏫 Target: %d / %d Sekolah Selesai" % [GameManager.schools_delivered_count, GameManager.total_schools]
	schools_label.set_position(Vector2(14, 150))
	schools_label.add_theme_font_size_override("font_size", 12)
	schools_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	left_dashboard.add_child(schools_label)

	# 3. Koin Perak Kerajaan (+5 per sekolah, Pajak 11%)
	coins_label = Label.new()
	coins_label.text = "🪙 Kas: %d Koin (+4 bersih/sekolah)" % GameManager.coins
	coins_label.set_position(Vector2(14, 168))
	coins_label.add_theme_font_size_override("font_size", 12)
	coins_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	left_dashboard.add_child(coins_label)

	# Posisi slider & tombol naik-turun mobil
	if steer_val_label:
		steer_val_label.set_position(Vector2(14, 190))
	if steer_slider:
		steer_slider.set_position(Vector2(14, 210))
	if walk_toggle_btn:
		walk_toggle_btn.set_position(Vector2(14, 238))
		walk_toggle_btn.set_size(Vector2(222, 32))

	# 4. Tombol Season (Kemarau / Hujan / Malam)
	season_btn = Button.new()
	season_btn.text = "☀️ Musim: Kemarau (Klik Ubah)"
	season_btn.set_position(Vector2(14, 276))
	season_btn.set_size(Vector2(222, 28))
	season_btn.add_theme_font_size_override("font_size", 11)
	season_btn.pressed.connect(_on_season_toggle_pressed)
	left_dashboard.add_child(season_btn)

	# 5. Grid Tombol Menu Cepat (Bengkel, Perkakas, Panduan, Rumah)
	var btn_grid = GridContainer.new()
	btn_grid.columns = 2
	btn_grid.set_position(Vector2(14, 312))
	btn_grid.set_size(Vector2(222, 155))
	btn_grid.add_theme_constant_override("h_separation", 6)
	btn_grid.add_theme_constant_override("v_separation", 6)
	left_dashboard.add_child(btn_grid)

	bengkel_btn = Button.new()
	bengkel_btn.text = "🔧 Bengkel"
	bengkel_btn.custom_minimum_size = Vector2(108, 34)
	bengkel_btn.add_theme_font_size_override("font_size", 11)
	bengkel_btn.pressed.connect(func(): _open_modal(bengkel_modal))
	btn_grid.add_child(bengkel_btn)

	perkakas_btn = Button.new()
	perkakas_btn.text = "🛠️ Perkakas"
	perkakas_btn.custom_minimum_size = Vector2(108, 34)
	perkakas_btn.add_theme_font_size_override("font_size", 11)
	perkakas_btn.pressed.connect(func(): _open_modal(perkakas_modal))
	btn_grid.add_child(perkakas_btn)

	panduan_btn = Button.new()
	panduan_btn.text = "📖 Panduan [F1]"
	panduan_btn.custom_minimum_size = Vector2(108, 34)
	panduan_btn.add_theme_font_size_override("font_size", 11)
	panduan_btn.pressed.connect(func(): _open_modal(panduan_modal))
	btn_grid.add_child(panduan_btn)

	properti_btn = Button.new()
	properti_btn.text = "🏠 Rumah"
	properti_btn.custom_minimum_size = Vector2(108, 34)
	properti_btn.add_theme_font_size_override("font_size", 11)
	properti_btn.pressed.connect(func(): _open_modal(properti_modal))
	btn_grid.add_child(properti_btn)

	# Tombol Klakson di Dashboard
	var klakson_btn = Button.new()
	klakson_btn.text = "📢 Klakson [H]"
	klakson_btn.custom_minimum_size = Vector2(222, 28)
	klakson_btn.set_position(Vector2(14, 395))
	klakson_btn.add_theme_font_size_override("font_size", 11)
	klakson_btn.pressed.connect(_on_honk_pressed)
	left_dashboard.add_child(klakson_btn)

	# Tombol Ganti POV Kamera (Awal / Dalam Mobil / Chase)
	pov_cam_btn = Button.new()
	pov_cam_btn.text = "🎥 POV: Tinjauan Kota [C]"
	pov_cam_btn.custom_minimum_size = Vector2(222, 30)
	pov_cam_btn.set_position(Vector2(14, 428))
	pov_cam_btn.add_theme_font_size_override("font_size", 11)
	pov_cam_btn.pressed.connect(_on_pov_cam_pressed)
	left_dashboard.add_child(pov_cam_btn)

	# Tombol Buka Peta Penuh di bawah minimap
	map_toggle_btn = Button.new()
	map_toggle_btn.text = "🗺️ Buka Peta Besar [M]"
	map_toggle_btn.set_position(Vector2(1040, 184))
	map_toggle_btn.set_size(Vector2(220, 28))
	map_toggle_btn.add_theme_font_size_override("font_size", 11)
	map_toggle_btn.pressed.connect(_on_map_toggle_pressed)
	add_child(map_toggle_btn)

func _setup_prompt_ui() -> void:
	prompt_panel = Panel.new()
	prompt_panel.visible = false
	prompt_panel.custom_minimum_size = Vector2(460, 48)
	prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_panel.offset_left = -230
	prompt_panel.offset_top = -110
	prompt_panel.offset_right = 230
	prompt_panel.offset_bottom = -62
	prompt_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.08, 0.12, 0.18, 0.95), Color(1.0, 0.8, 0.2, 0.9)))
	add_child(prompt_panel)

	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 13)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	prompt_panel.add_child(prompt_label)

func _setup_modals() -> void:
	panduan_modal = _build_panduan_modal()
	bengkel_modal = _build_bengkel_modal()
	perkakas_modal = _build_perkakas_modal()
	properti_modal = _build_properti_modal()

	add_child(panduan_modal)
	add_child(bengkel_modal)
	add_child(perkakas_modal)
	add_child(properti_modal)

func _open_modal(modal: Panel) -> void:
	_close_all_modals()
	if modal:
		modal.visible = true
		_refresh_modal_data()

func _close_all_modals() -> void:
	if panduan_modal: panduan_modal.visible = false
	if bengkel_modal: bengkel_modal.visible = false
	if perkakas_modal: perkakas_modal.visible = false
	if properti_modal: properti_modal.visible = false

func _build_panduan_modal() -> Panel:
	var p = Panel.new()
	p.visible = false
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -340
	p.offset_top = -240
	p.offset_right = 340
	p.offset_bottom = 240
	p.add_theme_stylebox_override("panel", _create_panel_style(Color(0.05, 0.08, 0.14, 0.96), Color(0.2, 0.6, 0.9, 0.9)))

	var title = Label.new()
	title.text = "📖 PANDUAN TITAH RAJA ARI: MISI MBG"
	title.set_position(Vector2(20, 16))
	title.set_size(Vector2(640, 28))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	p.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.set_position(Vector2(24, 52))
	scroll.set_size(Vector2(632, 325))
	p.add_child(scroll)

	var content = Label.new()
	content.custom_minimum_size = Vector2(610, 0)
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_theme_font_size_override("font_size", 12)
	content.text = """🎮 KONTROL PERMAINAN:
• [W][A][S][D] / Tombol Panah: Menyetir, maju, mundur, dan belok
• [Spasi]: Rem Tangan
• [E]: Masuk / Keluar Mobil (Beralih ke mode Pejalan Kaki)
• [C] / [V]: Ganti Sudut Pandang Kamera (Tinjauan Awal / Dalam Mobil Full / Chase)
• [H]: Bunyikan Klakson Resmi MBG
• [F]: Menambal Jalan Berlubang (Syarat: Miliki Sekop / Aspal di Toko Perkakas)
• [M]: Buka / Tutup Peta Besar Kota Tenjo
• [B]: Isi Bensin di SPBU (2 Koin/L) atau Beli Rumah Pribadi (2.500 Koin)
• [R]: Mulai Ulang Misi dari Dapur Sentral SPPG

🍱 ATURAN TITAH DISTRIBUSI:
1. Muat Ransum MBG di Dapur SPPG (Zona Hijau). Timer otomatis berjalan!
2. Antar ransum ke 5 SEKOLAH berurutan (SDN 01, SDN 02, SMPN 01, SDN 03, Madrasah).
3. Batas Waktu 5 MENIT (05:00)! Jangan sampai bel istirahat berbunyi.
4. Jaga Kondisi Ransum > 80% untuk meraih bintang 3 ★★★ kehormatan istana!

🪙 UPAH & POTONGAN PAJAK OTOMATIS 11%:
• Setiap pengantaran sekolah menghasilkan upah kotor 5 Koin Perak.
• Potongan Pajak Kas Kerajaan sebesar 11% (-1 Koin) disetorkan otomatis untuk kas istana.
• Pengawal menerima bersih +4 Koin Perak ke dompet pribadi!

⛽ BAHAN BAKAR & FASILITAS KOTA:
• Kapasitas tangki kendaraan: 40 Liter.
• Jika bensin menipis, kunjungi SPBU Tenjo di jalan lingkar selatan (2 Koin/Liter).
• Kunjungi Bengkel untuk upgrade Mesin, Turbo, Handling, dan Armor.
• Beli Rumah Mewah Tenjo seharga 2.500 Koin sebagai simbol keberhasilan pengawal!
• Season Malam: Lampu jalanan menyala, lampu sorot mobil aktif, dan Kuburan Keramat bercahaya gaib."""
	scroll.add_child(content)

	var close_btn = Button.new()
	close_btn.text = "Tutup Panduan [ESC]"
	close_btn.set_position(Vector2(240, 390))
	close_btn.set_size(Vector2(200, 36))
	close_btn.pressed.connect(_close_all_modals)
	p.add_child(close_btn)

	return p

func _build_bengkel_modal() -> Panel:
	var p = Panel.new()
	p.name = "BengkelModal"
	p.visible = false
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -300
	p.offset_top = -220
	p.offset_right = 300
	p.offset_bottom = 220
	p.add_theme_stylebox_override("panel", _create_panel_style(Color(0.06, 0.10, 0.16, 0.96), Color(1.0, 0.65, 0.1, 0.9)))

	var title = Label.new()
	title.text = "🔧 BENGKEL ARMADA MBG KERAJAAN"
	title.set_position(Vector2(20, 14))
	title.set_size(Vector2(560, 26))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	p.add_child(title)

	var sub = Label.new()
	sub.name = "BengkelSub"
	sub.text = "Kas Pengawal: %d Koin | Tingkatkan Performa Kendaraan" % GameManager.coins
	sub.set_position(Vector2(20, 40))
	sub.set_size(Vector2(560, 20))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	p.add_child(sub)

	var parts = [
		{"id": "engine", "name": "🚀 Mesin Utama", "desc": "Top Speed +10% / Level", "cost": 300, "y": 70},
		{"id": "turbo", "name": "⚡ Modul Turbo", "desc": "Akselerasi +15% / Level", "cost": 350, "y": 140},
		{"id": "handling", "name": "🧭 Kemudi & Rem", "desc": "Sensitivitas & Grip +15% / Level", "cost": 250, "y": 210},
		{"id": "armor", "name": "🛡️ Pelindung Ransum", "desc": "Ketahanan Makanan +20% / Level", "cost": 400, "y": 280}
	]

	for item in parts:
		var lbl = Label.new()
		lbl.name = "Lbl_" + item["id"]
		lbl.set_position(Vector2(30, item["y"]))
		lbl.set_size(Vector2(360, 48))
		lbl.add_theme_font_size_override("font_size", 12)
		p.add_child(lbl)

		var up_btn = Button.new()
		up_btn.name = "BtnUp_" + item["id"]
		up_btn.set_position(Vector2(410, item["y"] + 6))
		up_btn.set_size(Vector2(160, 32))
		up_btn.add_theme_font_size_override("font_size", 11)
		var part_id = item["id"]
		up_btn.pressed.connect(func(): _on_upgrade_part_pressed(part_id))
		p.add_child(up_btn)

	var close_btn = Button.new()
	close_btn.text = "Tutup Bengkel"
	close_btn.set_position(Vector2(210, 365))
	close_btn.set_size(Vector2(180, 34))
	close_btn.pressed.connect(_close_all_modals)
	p.add_child(close_btn)

	return p

func _build_perkakas_modal() -> Panel:
	var p = Panel.new()
	p.name = "PerkakasModal"
	p.visible = false
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -290
	p.offset_top = -200
	p.offset_right = 290
	p.offset_bottom = 200
	p.add_theme_stylebox_override("panel", _create_panel_style(Color(0.06, 0.11, 0.16, 0.96), Color(0.2, 0.8, 0.6, 0.9)))

	var title = Label.new()
	title.text = "🛠️ TOKO PERKAKAS JALANAN TENJO"
	title.set_position(Vector2(20, 14))
	title.set_size(Vector2(540, 26))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	p.add_child(title)

	var sub = Label.new()
	sub.name = "PerkakasSub"
	sub.text = "Kas Pengawal: %d Koin | Beli Alat untuk Menambal Jalan Rusak [F]" % GameManager.coins
	sub.set_position(Vector2(20, 40))
	sub.set_size(Vector2(540, 20))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
	p.add_child(sub)

	var tools = [
		{"id": "sekop", "y": 75},
		{"id": "aspal", "y": 155},
		{"id": "kit_perbaikan", "y": 235}
	]

	for t in tools:
		var lbl = Label.new()
		lbl.name = "LblTool_" + t["id"]
		lbl.set_position(Vector2(28, t["y"]))
		lbl.set_size(Vector2(350, 60))
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p.add_child(lbl)

		var buy_btn = Button.new()
		buy_btn.name = "BtnBuyTool_" + t["id"]
		buy_btn.set_position(Vector2(395, t["y"] + 10))
		buy_btn.set_size(Vector2(160, 34))
		buy_btn.add_theme_font_size_override("font_size", 11)
		var tool_id = t["id"]
		buy_btn.pressed.connect(func(): _on_buy_tool_pressed(tool_id))
		p.add_child(buy_btn)

	var close_btn = Button.new()
	close_btn.text = "Tutup Toko"
	close_btn.set_position(Vector2(200, 340))
	close_btn.set_size(Vector2(180, 34))
	close_btn.pressed.connect(_close_all_modals)
	p.add_child(close_btn)

	return p

func _build_properti_modal() -> Panel:
	var p = Panel.new()
	p.name = "PropertiModal"
	p.visible = false
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -260
	p.offset_top = -170
	p.offset_right = 260
	p.offset_bottom = 170
	p.add_theme_stylebox_override("panel", _create_panel_style(Color(0.06, 0.12, 0.18, 0.96), Color(0.85, 0.7, 0.2, 0.9)))

	var title = Label.new()
	title.text = "🏠 PROPERTI RUMAH PRIBADI PENGAWAL"
	title.set_position(Vector2(20, 16))
	title.set_size(Vector2(480, 26))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	p.add_child(title)

	var desc = Label.new()
	desc.name = "HouseDesc"
	desc.set_position(Vector2(24, 52))
	desc.set_size(Vector2(472, 160))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	p.add_child(desc)

	var action_btn = Button.new()
	action_btn.name = "BtnBuyHouse"
	action_btn.set_position(Vector2(140, 230))
	action_btn.set_size(Vector2(240, 38))
	action_btn.pressed.connect(_on_buy_house_modal_pressed)
	p.add_child(action_btn)

	var close_btn = Button.new()
	close_btn.text = "Tutup"
	close_btn.set_position(Vector2(170, 280))
	close_btn.set_size(Vector2(180, 30))
	close_btn.pressed.connect(_close_all_modals)
	p.add_child(close_btn)

	return p

func _create_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	return sb

func _refresh_modal_data() -> void:
	# Refresh Bengkel
	if bengkel_modal:
		var sub = bengkel_modal.get_node_or_null("BengkelSub") as Label
		if sub:
			sub.text = "Kas Pengawal: %d Koin | Tingkatkan Performa Kendaraan" % GameManager.coins

		for part_id in GameManager.vehicle_upgrades.keys():
			var lvl = GameManager.vehicle_upgrades[part_id]
			var cost = GameManager.upgrade_costs.get(part_id, 300)
			var lbl = bengkel_modal.get_node_or_null("Lbl_" + part_id) as Label
			var btn = bengkel_modal.get_node_or_null("BtnUp_" + part_id) as Button
			
			if lbl:
				var part_name = "Mesin" if part_id == "engine" else ("Turbo" if part_id == "turbo" else ("Handling" if part_id == "handling" else "Armor"))
				lbl.text = "%s (Level %d/3)\nEfek: +%d%% performa armada" % [part_name, lvl, lvl * 15]
			if btn:
				if lvl >= 3:
					btn.text = "✓ MAKSIMAL"
					btn.disabled = true
					btn.modulate = Color(0.3, 1.0, 0.4)
				else:
					btn.disabled = false
					btn.text = "Tingkatkan (%d Koin)" % cost
					btn.modulate = Color(1.0, 0.85, 0.2) if GameManager.coins >= cost else Color(1.0, 0.4, 0.4)

	# Refresh Toko Perkakas
	if perkakas_modal:
		var sub = perkakas_modal.get_node_or_null("PerkakasSub") as Label
		if sub:
			sub.text = "Kas Pengawal: %d Koin | Beli Alat untuk Menambal Jalan Rusak [F]" % GameManager.coins

		for tool_id in GameManager.tools_catalog.keys():
			var data = GameManager.tools_catalog[tool_id]
			var is_owned = GameManager.owned_tools.get(tool_id, false)
			var lbl = perkakas_modal.get_node_or_null("LblTool_" + tool_id) as Label
			var btn = perkakas_modal.get_node_or_null("BtnBuyTool_" + tool_id) as Button

			if lbl:
				lbl.text = "🛠️ %s (%d Koin)\n%s" % [data["name"], data["price"], data["desc"]]
			if btn:
				if is_owned:
					btn.text = "✓ SUDAH DIMILIKI"
					btn.disabled = true
					btn.modulate = Color(0.3, 1.0, 0.4)
				else:
					btn.disabled = false
					btn.text = "Beli (%d Koin)" % data["price"]
					btn.modulate = Color(1.0, 0.85, 0.2) if GameManager.coins >= data["price"] else Color(1.0, 0.4, 0.4)

	# Refresh Properti Rumah
	if properti_modal:
		var desc = properti_modal.get_node_or_null("HouseDesc") as Label
		var btn = properti_modal.get_node_or_null("BtnBuyHouse") as Button
		if desc:
			if GameManager.owns_house:
				desc.text = "👑 STATUS: LUNAS & HAK MILIK RESMI!\n\nSelamat Pengawal Raja Ari! Rumah pribadi asri berhalaman luas di Tenjo Island telah resmi menjadi tempat peristirahatan dan garasi armada MBG Anda."
				desc.modulate = Color(0.3, 1.0, 0.5)
			else:
				desc.text = "🏡 Vila Mewah Tenjo Island\nLokasi: Jalan Lingkar Selatan (Dekat SPBU)\nHarga: 2.500 Koin Perak\n\nHunian prestisius dengan halaman asri dan tiang bendera merah putih khusus pengawal kepercayaan istana."
				desc.modulate = Color(1.0, 0.9, 0.4)

		if btn:
			if GameManager.owns_house:
				btn.text = "✓ RUMAH SUDAH DIMILIKI"
				btn.disabled = true
				btn.modulate = Color(0.3, 1.0, 0.4)
			else:
				btn.disabled = false
				btn.text = "💰 Beli Rumah (2.500 Koin)"
				btn.modulate = Color(1.0, 0.85, 0.2) if GameManager.coins >= 2500 else Color(1.0, 0.4, 0.4)

func _on_upgrade_part_pressed(part_id: String) -> void:
	var success = GameManager.upgrade_vehicle_part(part_id)
	if success:
		show_toast("🔧 Upgrade %s berhasil ditingkatkan!" % part_id.capitalize(), 3.0)
		_refresh_modal_data()
	else:
		show_toast("💰 Koin kurang atau upgrade sudah maksimal!", 3.0)

func _on_buy_tool_pressed(tool_id: String) -> void:
	var success = GameManager.buy_tool(tool_id)
	if success:
		show_toast("🛠️ Berhasil membeli %s! Siap menambal rintangan jalan [F]." % GameManager.tools_catalog[tool_id]["name"], 3.5)
		_refresh_modal_data()
	else:
		show_toast("💰 Koin kurang untuk membeli perkakas ini!", 3.0)

func _on_buy_house_modal_pressed() -> void:
	var success = GameManager.buy_house()
	if success:
		show_toast("🏠 SELAMAT! Anda resmi menjadi pemilik Rumah Mewah Tenjo Island!", 4.0)
		_refresh_modal_data()
	else:
		show_toast("💰 Koin kurang! Butuh 2.500 koin untuk membeli rumah ini.", 3.0)

func _on_house_purchased() -> void:
	_refresh_modal_data()
	if properti_btn:
		properti_btn.text = "🏠 Rumah (Milik)"
		properti_btn.modulate = Color(0.3, 1.0, 0.4)

func _on_vehicle_upgraded(_part_name: String, _new_lvl: int) -> void:
	_refresh_modal_data()

func _on_honk_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_horn"):
		am.play_horn()
	show_toast("📢 KLAKSON MBG DIBUNYIKAN!", 1.5)

func _on_map_toggle_pressed() -> void:
	var minimap = get_node_or_null("Minimap")
	if minimap and minimap.has_method("toggle_map_size"):
		minimap.toggle_map_size()

func _on_pov_cam_pressed() -> void:
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("toggle_camera_mode"):
		cam.toggle_camera_mode()

func _on_camera_mode_changed(mode_name: String) -> void:
	if pov_cam_btn:
		pov_cam_btn.text = "🎥 POV: " + mode_name + " [C]"

func _on_season_toggle_pressed() -> void:
	GameManager.toggle_season()

func _on_season_changed(season_int: int) -> void:
	if season_btn:
		if season_int == GameManager.Season.HUJAN:
			season_btn.text = "🌧️ Musim: Hujan (Klik Ubah)"
			show_toast("🌧️ Cuaca: Musim Hujan! Jalanan basah dan licin, rem lebih hati-hati.", 3.5)
		elif season_int == GameManager.Season.MALAM:
			season_btn.text = "🌙 Musim: Malam (Klik Ubah)"
			show_toast("🌙 Cuaca: Musim Malam! Lampu sorot mobil aktif, area Kuburan Keramat bercahaya.", 3.5)
		else:
			season_btn.text = "☀️ Musim: Kemarau (Klik Ubah)"
			show_toast("☀️ Cuaca: Musim Kemarau! Jalanan kering dan cerah.", 3.0)

func _process(_delta: float) -> void:
	if player_car and steer_slider and steer_slider.value != player_car.steer_sensitivity:
		steer_slider.value = player_car.steer_sensitivity
		_update_steer_label(player_car.steer_sensitivity)

	_check_proximity_prompts()

func _check_proximity_prompts() -> void:
	if not prompt_panel or not prompt_label:
		return

	var active_body = player_pedestrian if (player_pedestrian and player_pedestrian.visible) else player_car
	if not active_body:
		prompt_panel.visible = false
		return

	var p_pos = active_body.global_position

	# Cek kedekatan SPBU (Vector3(18.0, 0.15, 40.0))
	var spbu_dist = p_pos.distance_to(Vector3(18.0, 0.15, 40.0))
	if spbu_dist <= 14.0:
		prompt_panel.visible = true
		if GameManager.current_fuel < GameManager.max_fuel:
			prompt_label.text = "⛽ SPBU TENJO (2 Koin/L) | Tahan [B] untuk isi bensin!"
			if Input.is_key_pressed(KEY_B):
				GameManager.refuel(get_process_delta_time())
				var am = get_node_or_null("/root/AudioManager")
				if am and am.has_method("play_coin_sfx") and randf() < 0.2:
					am.play_coin_sfx()
		else:
			prompt_label.text = "⛽ SPBU TENJO: Tangki bensin sudah PENUH (40.0 Liter)!"
		return

	# Cek kedekatan Rumah Pribadi (Vector3(26.0, 0.15, 42.0))
	var house_dist = p_pos.distance_to(Vector3(26.0, 0.15, 42.0))
	if house_dist <= 12.0:
		prompt_panel.visible = true
		if GameManager.owns_house:
			prompt_label.text = "🏠 RUMAH PRIBADI PENGAWAL RAJA ARI [HAK MILIK LUNAS]"
		else:
			prompt_label.text = "🏡 RUMAH MEWAH DIJUAL (2.500 Koin) | Tekan [B] untuk Beli Sekarang!"
			if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_B):
				_on_buy_house_modal_pressed()
		return

	# Cek kedekatan Kuburan Keramat (Vector3(-16.0, 0.15, -26.0))
	var grave_dist = p_pos.distance_to(Vector3(-16.0, 0.15, -26.0))
	if grave_dist <= 14.0:
		prompt_panel.visible = true
		if GameManager.current_season == GameManager.Season.MALAM:
			prompt_label.text = "🪦 KUBURAN LELUHUR TENJO: Lentera hijau menyala misterius di malam hari..."
		else:
			prompt_label.text = "🪦 KUBURAN LELUHUR TENJO: Makam bersejarah para pejuang pulau."
		return

	prompt_panel.visible = false

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

# Penyerahan ke sekolah dengan perincian upah kotor & potongan pajak 11%
func _on_school_delivered(school_idx: int, school_name: String, delivered_count: int, total_count: int, earned_coins: int) -> void:
	if schools_label:
		schools_label.text = "🏫 Target: %d / %d Sekolah Selesai" % [delivered_count, total_count]
		schools_label.modulate = Color(0.3, 1.0, 0.5)
	if coins_label:
		coins_label.text = "🪙 Kas: %d Koin (+4 bersih/sekolah)" % GameManager.coins
		
	var gross_earned = 5
	var tax_amount = 1
	var net_earned = earned_coins

	if delivered_count < total_count:
		var next_name = GameManager.schools_data[GameManager.current_school_idx]["name"]
		if nav_guide:
			nav_guide.text = "➔ Rute: Menuju Sekolah %d/%d: %s" % [GameManager.current_school_idx + 1, total_count, next_name]
		if driver_status:
			driver_status.text = "● Mengantar ke Sekolah %d/%d" % [GameManager.current_school_idx + 1, total_count]
		show_toast("🎉 %s Berhasil!\n💵 Upah: +%d | 👑 Pajak Istana (11%%): -%d | 🪙 Bersih: +%d Koin!\n➔ Lanjut ke %s" % [school_name, gross_earned, tax_amount, net_earned, next_name], 4.5)
	else:
		if nav_guide:
			nav_guide.text = "🎉 SELURUH 5 SEKOLAH SELESAI!"
		show_toast("🏆 SELURUH 5 SEKOLAH SUKSES MENERIMA MBG!\n💵 Upah: +%d Koin | 👑 Pajak Kerajaan: -%d Koin | 🪙 Kas Bertambah: +%d Koin!" % [gross_earned, tax_amount, net_earned], 5.0)

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
		coins_label.text = "🪙 Kas: %d Koin (+4 bersih/sekolah)" % new_coins
	_refresh_modal_data()

# Visual countdown dengan efek urgensi saat waktu < 60 detik
func _on_time_changed(val: float) -> void:
	var mins = int(val / 60.0)
	var secs = int(val) % 60
	if timer_label:
		if val < 60.0 and val > 0.0:
			timer_label.text = "⚠️ KRITIS: %02d:%02d ⚠️" % [mins, secs]
			timer_label.modulate = Color(1.0, 0.2, 0.2)
			var pulse = 1.0 + 0.12 * sin(Time.get_ticks_msec() * 0.012)
			timer_label.scale = Vector2(pulse, pulse)
		else:
			timer_label.text = "⏱️ Waktu: %02d:%02d" % [mins, secs]
			timer_label.modulate = Color.WHITE
			timer_label.scale = Vector2.ONE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_on_restart_pressed()
		elif event.keycode == KEY_F1 or event.keycode == KEY_P:
			if panduan_modal and panduan_modal.visible:
				_close_all_modals()
			else:
				_open_modal(panduan_modal)
		elif event.keycode == KEY_ESCAPE:
			_close_all_modals()
		elif event.keycode == KEY_H:
			_on_honk_pressed()

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
		modal_detail.text = "5 Sekolah Selesai | Skor: %d | Total Kas: %d Koin | Pajak Disetor: %d Koin" % [score, GameManager.coins, GameManager.total_tax_paid]
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
