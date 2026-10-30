extends Control

@onready var coin_label: Label = $TopBar/CoinPanel/CoinLabel
@onready var start_button: Button = $StartSection/StartButton

# Driver Cards
@onready var driver_cards = {
	"fatur": {
		"panel": $DriverSection/DriverContainer/CardFatur,
		"btn": $DriverSection/DriverContainer/CardFatur/SelectBtn
	},
	"mahdi": {
		"panel": $DriverSection/DriverContainer/CardMahdi,
		"btn": $DriverSection/DriverContainer/CardMahdi/SelectBtn
	},
	"zen": {
		"panel": $DriverSection/DriverContainer/CardZen,
		"btn": $DriverSection/DriverContainer/CardZen/SelectBtn
	}
}

# Vehicle Container
@onready var vehicle_container: HBoxContainer = $VehicleSection/VehicleContainer

# Dynamic vehicle UI references
var dynamic_vehicle_cards: Dictionary = {}

# Menu Modals
var panduan_modal: Panel
var bengkel_modal: Panel
var perkakas_modal: Panel

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	_update_coin_display()
	
	_setup_driver_buttons()
	_setup_dynamic_vehicles()
	_setup_menu_extra_buttons()
	_setup_menu_modals()
	
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		
	_refresh_all_ui()

func _update_coin_display() -> void:
	if coin_label:
		coin_label.text = "🪙 Koin MBG: %d" % GameManager.coins

func _on_coins_changed(_new_coins: int) -> void:
	_update_coin_display()
	_refresh_vehicle_ui()
	_refresh_modal_data()

func _setup_driver_buttons() -> void:
	for id in driver_cards.keys():
		var btn = driver_cards[id]["btn"] as Button
		if btn:
			btn.pressed.connect(func(): _on_driver_selected(id))

func _setup_dynamic_vehicles() -> void:
	if not vehicle_container:
		return

	# Bersihkan child lama di vehicle_container
	for child in vehicle_container.get_children():
		child.queue_free()

	dynamic_vehicle_cards.clear()

	# Buat 5 kartu mobil resmi sesuai GameManager.vehicle_catalog
	for v_id in GameManager.vehicle_catalog.keys():
		var v_data = GameManager.vehicle_catalog[v_id]
		var card = _create_vehicle_card(v_id, v_data)
		vehicle_container.add_child(card)

func _create_vehicle_card(v_id: String, v_data: Dictionary) -> Panel:
	var card = Panel.new()
	card.name = "Card_" + v_id
	card.custom_minimum_size = Vector2(230, 205)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _create_card_style())

	# Thumbnail Gambar Mobil
	var thumb = TextureRect.new()
	thumb.set_position(Vector2(10, 8))
	thumb.set_size(Vector2(70, 60))
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var t_path = v_data.get("thumb_path", "")
	if ResourceLoader.exists(t_path):
		thumb.texture = load(t_path)
	card.add_child(thumb)

	# Nama Mobil
	var name_lbl = Label.new()
	name_lbl.text = v_data.get("name", "Armada MBG")
	name_lbl.set_position(Vector2(86, 8))
	name_lbl.set_size(Vector2(136, 36))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	card.add_child(name_lbl)

	# Harga
	var price_lbl = Label.new()
	var price = v_data.get("price", 0)
	price_lbl.name = "PriceLabel"
	price_lbl.text = "● GRATIS (STARTER)" if price == 0 else "💰 HARGA: %d KOIN" % price
	price_lbl.set_position(Vector2(86, 46))
	price_lbl.set_size(Vector2(136, 20))
	price_lbl.add_theme_font_size_override("font_size", 11)
	price_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.5) if price == 0 else Color(1.0, 0.85, 0.2))
	card.add_child(price_lbl)

	# Spesifikasi & Deskripsi
	var specs_lbl = Label.new()
	var spd = v_data.get("speed_mult", 1.0)
	var acc = v_data.get("accel_mult", 1.0)
	var dur = v_data.get("durability_mult", 1.0)
	specs_lbl.text = "Top Speed: %.2fx | Accel: %.2fx | Armor: %.2fx\n%s" % [spd, acc, dur, v_data.get("desc", "")]
	specs_lbl.set_position(Vector2(10, 72))
	specs_lbl.set_size(Vector2(210, 85))
	specs_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	specs_lbl.add_theme_font_size_override("font_size", 10)
	specs_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 0.85))
	card.add_child(specs_lbl)

	# Tombol Aksi Beli / Pakai
	var act_btn = Button.new()
	act_btn.name = "ActionBtn"
	act_btn.set_position(Vector2(10, 164))
	act_btn.set_size(Vector2(210, 32))
	act_btn.add_theme_font_size_override("font_size", 11)
	act_btn.pressed.connect(func(): _on_vehicle_action(v_id))
	card.add_child(act_btn)

	dynamic_vehicle_cards[v_id] = {
		"panel": card,
		"btn": act_btn,
		"price_lbl": price_lbl
	}

	return card

func _setup_menu_extra_buttons() -> void:
	# Tambahkan tombol menu ekstra di TopBar samping CoinPanel
	var top_bar = get_node_or_null("TopBar")
	if not top_bar:
		return

	var menu_btn_container = HBoxContainer.new()
	menu_btn_container.set_position(Vector2(440, 16))
	menu_btn_container.set_size(Vector2(540, 44))
	menu_btn_container.add_theme_constant_override("separation", 10)
	top_bar.add_child(menu_btn_container)

	var btn_guide = Button.new()
	btn_guide.text = "📖 PANDUAN MAIN"
	btn_guide.custom_minimum_size = Vector2(130, 40)
	btn_guide.add_theme_font_size_override("font_size", 12)
	btn_guide.pressed.connect(func(): _open_menu_modal(panduan_modal))
	menu_btn_container.add_child(btn_guide)

	var btn_bengkel = Button.new()
	btn_bengkel.text = "🔧 BENGKEL"
	btn_bengkel.custom_minimum_size = Vector2(110, 40)
	btn_bengkel.add_theme_font_size_override("font_size", 12)
	btn_bengkel.pressed.connect(func(): _open_menu_modal(bengkel_modal))
	menu_btn_container.add_child(btn_bengkel)

	var btn_perkakas = Button.new()
	btn_perkakas.text = "🛠️ PERKAKAS"
	btn_perkakas.custom_minimum_size = Vector2(110, 40)
	btn_perkakas.add_theme_font_size_override("font_size", 12)
	btn_perkakas.pressed.connect(func(): _open_menu_modal(perkakas_modal))
	menu_btn_container.add_child(btn_perkakas)

	var btn_story = Button.new()
	btn_story.text = "📜 KISAH TITAH RAJA"
	btn_story.custom_minimum_size = Vector2(150, 40)
	btn_story.add_theme_font_size_override("font_size", 12)
	btn_story.modulate = Color(1.0, 0.85, 0.3)
	btn_story.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/story_cutscene.tscn"))
	menu_btn_container.add_child(btn_story)

func _setup_menu_modals() -> void:
	panduan_modal = _create_panduan_modal()
	bengkel_modal = _create_bengkel_modal()
	perkakas_modal = _create_perkakas_modal()

	add_child(panduan_modal)
	add_child(bengkel_modal)
	add_child(perkakas_modal)

func _open_menu_modal(modal: Panel) -> void:
	_close_all_modals()
	if modal:
		modal.visible = true
		_refresh_modal_data()

func _close_all_modals() -> void:
	if panduan_modal: panduan_modal.visible = false
	if bengkel_modal: bengkel_modal.visible = false
	if perkakas_modal: perkakas_modal.visible = false

func _create_panduan_modal() -> Panel:
	var p = Panel.new()
	p.visible = false
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -340
	p.offset_top = -240
	p.offset_right = 340
	p.offset_bottom = 240
	p.add_theme_stylebox_override("panel", _create_modal_style(Color(0.05, 0.08, 0.14, 0.96), Color(0.2, 0.6, 0.9, 0.9)))

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

func _create_bengkel_modal() -> Panel:
	var p = Panel.new()
	p.name = "MenuBengkelModal"
	p.visible = false
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -300
	p.offset_top = -220
	p.offset_right = 300
	p.offset_bottom = 220
	p.add_theme_stylebox_override("panel", _create_modal_style(Color(0.06, 0.10, 0.16, 0.96), Color(1.0, 0.65, 0.1, 0.9)))

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
		up_btn.pressed.connect(func(): _on_menu_upgrade_part(part_id))
		p.add_child(up_btn)

	var close_btn = Button.new()
	close_btn.text = "Tutup Bengkel"
	close_btn.set_position(Vector2(210, 365))
	close_btn.set_size(Vector2(180, 34))
	close_btn.pressed.connect(_close_all_modals)
	p.add_child(close_btn)

	return p

func _create_perkakas_modal() -> Panel:
	var p = Panel.new()
	p.name = "MenuPerkakasModal"
	p.visible = false
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -290
	p.offset_top = -200
	p.offset_right = 290
	p.offset_bottom = 200
	p.add_theme_stylebox_override("panel", _create_modal_style(Color(0.06, 0.11, 0.16, 0.96), Color(0.2, 0.8, 0.6, 0.9)))

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
		buy_btn.pressed.connect(func(): _on_menu_buy_tool(tool_id))
		p.add_child(buy_btn)

	var close_btn = Button.new()
	close_btn.text = "Tutup Toko"
	close_btn.set_position(Vector2(200, 340))
	close_btn.set_size(Vector2(180, 34))
	close_btn.pressed.connect(_close_all_modals)
	p.add_child(close_btn)

	return p

func _create_card_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.1, 0.16, 0.88)
	sb.border_color = Color(0.18, 0.45, 0.75, 0.8)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	return sb

func _create_modal_style(bg: Color, border: Color) -> StyleBoxFlat:
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

func _on_menu_upgrade_part(part_id: String) -> void:
	var success = GameManager.upgrade_vehicle_part(part_id)
	if success:
		_refresh_modal_data()
		_update_coin_display()
	else:
		print("[Bengkel] Koin kurang atau upgrade sudah maksimal!")

func _on_menu_buy_tool(tool_id: String) -> void:
	var success = GameManager.buy_tool(tool_id)
	if success:
		_refresh_modal_data()
		_update_coin_display()
	else:
		print("[Perkakas] Koin kurang!")

func _refresh_modal_data() -> void:
	# Update Bengkel modal
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

	# Update Perkakas modal
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

func _on_driver_selected(driver_id: String) -> void:
	GameManager.select_driver(driver_id)
	_refresh_driver_ui()

func _on_vehicle_action(vehicle_id: String) -> void:
	if GameManager.owned_vehicles.has(vehicle_id):
		GameManager.select_vehicle(vehicle_id)
		_refresh_vehicle_ui()
	else:
		var success = GameManager.buy_vehicle(vehicle_id)
		if success:
			_refresh_vehicle_ui()
			_update_coin_display()
		else:
			var price = GameManager.vehicle_catalog[vehicle_id]["price"]
			print("[MBG] Koin kurang! Butuh %d koin." % price)

func _refresh_all_ui() -> void:
	_refresh_driver_ui()
	_refresh_vehicle_ui()

func _refresh_driver_ui() -> void:
	var sel = GameManager.selected_driver_id
	for id in driver_cards.keys():
		var is_selected = (id == sel)
		var btn = driver_cards[id]["btn"] as Button
		var panel = driver_cards[id]["panel"] as Panel
		
		if btn:
			if is_selected:
				btn.text = "✓ TERPILIH"
				btn.modulate = Color(0.3, 1.0, 0.4)
			else:
				btn.text = "PILIH DRIVER"
				btn.modulate = Color.WHITE
				
		if panel:
			panel.self_modulate = Color(1.2, 1.2, 1.0) if is_selected else Color(0.85, 0.85, 0.9)

func _refresh_vehicle_ui() -> void:
	var sel = GameManager.selected_vehicle_id
	var owned = GameManager.owned_vehicles
	
	for id in dynamic_vehicle_cards.keys():
		var is_selected = (id == sel)
		var is_owned = owned.has(id)
		var btn = dynamic_vehicle_cards[id]["btn"] as Button
		var panel = dynamic_vehicle_cards[id]["panel"] as Panel
		var data = GameManager.vehicle_catalog.get(id, {})
		
		if btn:
			if is_selected:
				btn.text = "✓ TERPILIH"
				btn.modulate = Color(0.3, 1.0, 0.4)
			elif is_owned:
				btn.text = "PAKAI MOBIL"
				btn.modulate = Color(0.4, 0.85, 1.0)
			else:
				var price = data.get("price", 0)
				btn.text = "💰 BELI (%d KOIN)" % price
				if GameManager.coins >= price:
					btn.modulate = Color(1.0, 0.85, 0.2)
				else:
					btn.modulate = Color(1.0, 0.4, 0.4)
					
		if panel:
			panel.self_modulate = Color(1.2, 1.2, 1.0) if is_selected else Color(0.85, 0.85, 0.9)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_close_all_modals()
		elif event.keycode == KEY_F1:
			if panduan_modal and panduan_modal.visible:
				_close_all_modals()
			else:
				_open_menu_modal(panduan_modal)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/story_cutscene.tscn")
