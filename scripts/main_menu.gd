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

# Vehicle Cards
@onready var vehicle_cards = {
	"van_standard": {
		"panel": $VehicleSection/VehicleContainer/CardVan,
		"btn": $VehicleSection/VehicleContainer/CardVan/ActionBtn
	},
	"pickup_express": {
		"panel": $VehicleSection/VehicleContainer/CardPickup,
		"btn": $VehicleSection/VehicleContainer/CardPickup/ActionBtn
	},
	"truck_heavy": {
		"panel": $VehicleSection/VehicleContainer/CardTruck,
		"btn": $VehicleSection/VehicleContainer/CardTruck/ActionBtn
	}
}

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	_update_coin_display()
	
	_setup_driver_buttons()
	_setup_vehicle_buttons()
	
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		
	_refresh_all_ui()

func _update_coin_display() -> void:
	if coin_label:
		coin_label.text = "🪙 Koin Perak: %d" % GameManager.coins

func _on_coins_changed(_new_coins: int) -> void:
	_update_coin_display()
	_refresh_vehicle_ui()

func _setup_driver_buttons() -> void:
	for id in driver_cards.keys():
		var btn = driver_cards[id]["btn"] as Button
		if btn:
			btn.pressed.connect(func(): _on_driver_selected(id))

func _setup_vehicle_buttons() -> void:
	for id in vehicle_cards.keys():
		var btn = vehicle_cards[id]["btn"] as Button
		if btn:
			btn.pressed.connect(func(): _on_vehicle_action(id))

func _on_driver_selected(driver_id: String) -> void:
	GameManager.select_driver(driver_id)
	_refresh_driver_ui()

func _on_vehicle_action(vehicle_id: String) -> void:
	if GameManager.owned_vehicles.has(vehicle_id):
		GameManager.select_vehicle(vehicle_id)
		_refresh_vehicle_ui()
	else:
		# Beli mobil menggunakan koin
		var success = GameManager.buy_vehicle(vehicle_id)
		if success:
			_refresh_vehicle_ui()
			_update_coin_display()
		else:
			# Efek getar atau notifikasi koin kurang
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
	
	for id in vehicle_cards.keys():
		var is_selected = (id == sel)
		var is_owned = owned.has(id)
		var btn = vehicle_cards[id]["btn"] as Button
		var panel = vehicle_cards[id]["panel"] as Panel
		var data = GameManager.vehicle_catalog[id]
		
		if btn:
			if is_selected:
				btn.text = "✓ TERPILIH"
				btn.modulate = Color(0.3, 1.0, 0.4)
			elif is_owned:
				btn.text = "PAKAI MOBIL"
				btn.modulate = Color(0.4, 0.85, 1.0)
			else:
				btn.text = "💰 BELI (%d KOIN)" % data["price"]
				if GameManager.coins >= data["price"]:
					btn.modulate = Color(1.0, 0.85, 0.2)
				else:
					btn.modulate = Color(1.0, 0.4, 0.4)
					
		if panel:
			panel.self_modulate = Color(1.2, 1.2, 1.0) if is_selected else Color(0.85, 0.85, 0.9)

func _on_start_pressed() -> void:
	# Beralih ke adegan naskah cerita dan opening cutscene
	get_tree().change_scene_to_file("res://scenes/ui/story_cutscene.tscn")
