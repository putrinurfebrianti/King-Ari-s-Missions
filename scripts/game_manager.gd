extends Node

signal food_changed(current_food: float)
signal time_changed(seconds_left: float)
signal fuel_changed(current_fuel: float, max_fuel: float)
signal school_delivered(school_idx: int, school_name: String, delivered_count: int, total_count: int, earned_coins: int)
signal delivery_started()
signal mission_completed(stars: int, final_score: int, earned_coins: int)
signal mission_failed(reason: String)
signal coins_changed(new_coins: int)
signal season_changed(season: int)
signal house_purchased()
signal pothole_repaired(pothole_pos: Vector3)
signal vehicle_upgraded(part_name: String, new_level: int)

enum State { AT_SPPG, DELIVERING, FINISHED, FAILED }
var current_state: State = State.AT_SPPG

enum Season { KEMARAU, HUJAN, MALAM }
var current_season: Season = Season.KEMARAU

var food_condition: float = 100.0
var time_left: float = 300.0 # 5 Menit (05:00) sesuai GDD Titah Pertama Raja Ari
var total_time: float = 300.0

# Sistem Bahan Bakar (GDD Bab 5.4 & 10.2: 40 Liter Kapasitas)
var max_fuel: float = 40.0
var current_fuel: float = 40.0
var is_refueling: bool = false
var fuel_price_per_liter: float = 2.0 # 2 Koin per Liter di SPBU Tenjo
var fuel_buy_accumulator: float = 0.0

# Kondisi Awal Pemain: Uang Rp 5.000 (5000 Koin) + Bensin 40L + Mobil Basic
var coins: int = 5000
var tax_rate: float = 0.11 # Potongan Pajak Kas Kerajaan Otomatis 11%
var total_tax_paid: int = 0

var selected_driver_id: String = "fatur"
var selected_vehicle_id: String = "van_standard"
var owned_vehicles: Array[String] = ["van_standard"]

# Sistem Real Estate (Beli Rumah di Tenjo Island)
var owns_house: bool = false
var house_price: int = 2500

# Sistem Upgrade Kendaraan (Bengkel)
var vehicle_upgrades: Dictionary = {
	"engine": 0,    # Max 3: Top Speed +10% per level (300 koin)
	"turbo": 0,     # Max 3: Akselerasi +15% per level (350 koin)
	"handling": 0,  # Max 3: Kemudi & Rem +15% per level (250 koin)
	"armor": 0      # Max 3: Ketahanan Makanan +20% per level (400 koin)
}

var upgrade_costs: Dictionary = {
	"engine": 300,
	"turbo": 350,
	"handling": 250,
	"armor": 400
}

# Sistem Perkakas Perbaikan Jalan
var tools_catalog: Dictionary = {
	"sekop": {
		"name": "Sekop Taktis Kerajaan",
		"price": 250,
		"desc": "Alat pengeruk material jalan amblas untuk membuka jalan darurat."
	},
	"aspal": {
		"name": "Ember Aspal Cepat Kering",
		"price": 400,
		"desc": "Aspal instan bermutu tinggi untuk menambal jalan berlubang secara permanen."
	},
	"kit_perbaikan": {
		"name": "Kit Perbaikan Jalan Lengkap",
		"price": 750,
		"desc": "Paket perkakas komplit (sekop + aspal + dongkrak) untuk meratakan rintangan."
	}
}
var owned_tools: Dictionary = {
	"sekop": false,
	"aspal": false,
	"kit_perbaikan": false
}

# Database 5 Sekolah Tujuan Distribusi MBG (GDD Bab 4.2 & 12.2)
var schools_data: Array[Dictionary] = [
	{
		"id": 0,
		"name": "SDN 01 Tenjo",
		"short_name": "SDN 01",
		"pos": Vector3(32.0, 0.15, -24.0),
		"delivered": false
	},
	{
		"id": 1,
		"name": "SDN 02 Harapan",
		"short_name": "SDN 02",
		"pos": Vector3(-32.0, 0.15, -24.0),
		"delivered": false
	},
	{
		"id": 2,
		"name": "SMPN 01 Nusa",
		"short_name": "SMPN 01",
		"pos": Vector3(48.0, 0.15, -16.0),
		"delivered": false
	},
	{
		"id": 3,
		"name": "SDN 03 Garuda",
		"short_name": "SDN 03",
		"pos": Vector3(44.0, 0.15, 24.0),
		"delivered": false
	},
	{
		"id": 4,
		"name": "Madrasah Tenjo",
		"short_name": "Madrasah",
		"pos": Vector3(-30.0, 0.15, 24.0),
		"delivered": false
	}
]
var current_school_idx: int = 0
var schools_delivered_count: int = 0
var total_schools: int = 5

# Database Karakter Trio Driver Pengawal Raja Ari (GDD Bab 3 & 8.2)
var driver_profiles: Dictionary = {
	"fatur": {
		"id": "fatur",
		"name": "Fatur 'Si Kilat'",
		"title": "Pengawal Kepercayaan Raja Ari",
		"portrait_path": "res://assets/textures/characters/driver_fatur_portrait.png",
		"passive": "⚡ Akselerasi +15% & Kecepatan +10%. Pengawal gesit pembuka jalan titah raja.",
		"accel_mult": 1.15,
		"speed_mult": 1.10,
		"decay_mult": 1.10,
		"steer_mult": 1.0
	},
	"mahdi": {
		"id": "mahdi",
		"name": "Mahdi 'Si Kompas'",
		"title": "Pengawal Kepercayaan Raja Ari",
		"portrait_path": "res://assets/textures/characters/driver_mahdi_portrait.png",
		"passive": "🧭 Kemudi Tajam (+25%). Ahli navigasi menembus jalanan sempit dan blokade demonstrasi warga.",
		"accel_mult": 1.0,
		"speed_mult": 1.0,
		"decay_mult": 1.0,
		"steer_mult": 1.25
	},
	"zen": {
		"id": "zen",
		"name": "Zen 'Si Penjaga Ransum'",
		"title": "Pengawal Kepercayaan Raja Ari",
		"portrait_path": "res://assets/textures/characters/driver_zen_portrait.png",
		"passive": "🛡️ Pelindung Ransum: Kerusakan makanan akibat benturan & jalan berlubang berkurang 25%. Makanan tetap higienis.",
		"accel_mult": 0.95,
		"speed_mult": 0.98,
		"decay_mult": 0.75,
		"steer_mult": 1.0
	}
}

# 5 Pilihan Mobil Upgrade (GDD Bab 10.1 & Task User)
var vehicle_catalog: Dictionary = {
	"van_standard": {
		"id": "van_standard",
		"name": "1. Van MBG Dinas Kerajaan",
		"price": 0,
		"thumb_path": "res://assets/textures/ui/vehicle_van.png",
		"desc": "Kendaraan dinas MBG standar berpelat resmi istana. Seimbang dan handal untuk pemula.",
		"speed_mult": 1.0,
		"accel_mult": 1.0,
		"durability_mult": 1.0
	},
	"pickup_express": {
		"id": "pickup_express",
		"name": "2. Pick-Up MBG Patroli Cepat",
		"price": 1200,
		"thumb_path": "res://assets/textures/ui/vehicle_pickup.png",
		"desc": "Armada pick-up MBG resmi bertenaga turbo (+25% akselerasi) untuk menembus rute terjal.",
		"speed_mult": 1.15,
		"accel_mult": 1.25,
		"durability_mult": 0.9
	},
	"sedan_vvip": {
		"id": "sedan_vvip",
		"name": "3. Sedan Listrik Pengawal VVIP",
		"price": 2000,
		"thumb_path": "res://assets/textures/ui/vehicle_van.png",
		"desc": "Mobil sedan listrik prototipe kerajaan dengan kecepatan tertinggi dan handling ekstra presisi.",
		"speed_mult": 1.30,
		"accel_mult": 1.15,
		"durability_mult": 1.1
	},
	"minibus_fleet": {
		"id": "minibus_fleet",
		"name": "4. Minibus MBG Ransum Jumbo",
		"price": 3200,
		"thumb_path": "res://assets/textures/ui/vehicle_truck.png",
		"desc": "Minibus kapasitas besar berperedam kejut mutakhir (+40% ketahanan makanan).",
		"speed_mult": 1.05,
		"accel_mult": 1.05,
		"durability_mult": 1.4
	},
	"truck_heavy": {
		"id": "truck_heavy",
		"name": "5. Truk MBG Armor Heavy-Duty",
		"price": 4500,
		"thumb_path": "res://assets/textures/ui/vehicle_truck.png",
		"desc": "Armada boks berpelindung baja anti-guncangan (+60% ketahanan ransum) mandat khusus Raja Ari.",
		"speed_mult": 1.10,
		"accel_mult": 0.95,
		"durability_mult": 1.6
	}
}

func _ready() -> void:
	reset_game()

func _process(delta: float) -> void:
	if current_state == State.DELIVERING:
		time_left -= delta
		time_changed.emit(time_left)
		if time_left <= 0.0:
			time_left = 0.0
			fail_mission("Waktu habis (05:00)! Bel sekolah telah berbunyi sebelum seluruh makanan terkirim.")
			
		# Pengisian bahan bakar berbayar di SPBU
		if is_refueling:
			refuel(delta)

func reset_game() -> void:
	current_state = State.DELIVERING
	food_condition = 100.0
	time_left = 300.0 # 5 menit (05:00) hitung mundur aktif
	current_fuel = max_fuel
	is_refueling = false
	current_school_idx = 0
	schools_delivered_count = 0
	
	for i in range(schools_data.size()):
		schools_data[i]["delivered"] = false
		
	food_changed.emit(food_condition)
	time_changed.emit(time_left)
	fuel_changed.emit(current_fuel, max_fuel)
	coins_changed.emit(coins)
	delivery_started.emit()

func set_season(new_season: Season) -> void:
	current_season = new_season
	season_changed.emit(int(current_season))

func toggle_season() -> void:
	if current_season == Season.KEMARAU:
		set_season(Season.HUJAN)
	elif current_season == Season.HUJAN:
		set_season(Season.MALAM)
	else:
		set_season(Season.KEMARAU)

func get_active_driver() -> Dictionary:
	return driver_profiles.get(selected_driver_id, driver_profiles["fatur"])

func get_active_vehicle() -> Dictionary:
	return vehicle_catalog.get(selected_vehicle_id, vehicle_catalog["van_standard"])

func select_driver(driver_id: String) -> void:
	if driver_profiles.has(driver_id):
		selected_driver_id = driver_id

func select_vehicle(vehicle_id: String) -> void:
	if vehicle_catalog.has(vehicle_id) and owned_vehicles.has(vehicle_id):
		selected_vehicle_id = vehicle_id

func buy_vehicle(vehicle_id: String) -> bool:
	if not vehicle_catalog.has(vehicle_id):
		return false
	if owned_vehicles.has(vehicle_id):
		select_vehicle(vehicle_id)
		return true
	
	var price = vehicle_catalog[vehicle_id]["price"]
	if coins >= price:
		coins -= price
		owned_vehicles.append(vehicle_id)
		selected_vehicle_id = vehicle_id
		coins_changed.emit(coins)
		return true
	return false

# Sistem Upgrade Kendaraan (Bengkel)
func upgrade_vehicle_part(part_name: String) -> bool:
	if not vehicle_upgrades.has(part_name):
		return false
	var cur_lvl = vehicle_upgrades[part_name]
	if cur_lvl >= 3:
		return false # Sudah maksimal
		
	var cost = upgrade_costs.get(part_name, 300)
	if coins >= cost:
		coins -= cost
		vehicle_upgrades[part_name] += 1
		coins_changed.emit(coins)
		vehicle_upgraded.emit(part_name, vehicle_upgrades[part_name])
		return true
	return false

# Sistem Toko Perkakas
func buy_tool(tool_id: String) -> bool:
	if not tools_catalog.has(tool_id):
		return false
	if owned_tools.get(tool_id, false):
		return true
	var price = tools_catalog[tool_id]["price"]
	if coins >= price:
		coins -= price
		owned_tools[tool_id] = true
		coins_changed.emit(coins)
		return true
	return false

func has_any_repair_tool() -> bool:
	return owned_tools.get("sekop", false) or owned_tools.get("aspal", false) or owned_tools.get("kit_perbaikan", false)

# Sistem Real Estate (Beli Rumah)
func buy_house() -> bool:
	if owns_house:
		return true
	if coins >= house_price:
		coins -= house_price
		owns_house = true
		coins_changed.emit(coins)
		house_purchased.emit()
		return true
	return false

func start_delivery() -> void:
	if current_state == State.AT_SPPG:
		current_state = State.DELIVERING
		food_condition = 100.0
		time_left = 300.0
		current_fuel = max_fuel
		current_school_idx = 0
		schools_delivered_count = 0
		food_changed.emit(food_condition)
		delivery_started.emit()
		print("[KingAri] Titah Raja Dimulai! Ransum dimuat di SPPG. Menuju Sekolah 1/5.")

func get_active_target_pos() -> Vector3:
	if current_state == State.AT_SPPG:
		return Vector3(-50.0, 0.15, -2.0) # SPPG
	if current_school_idx < schools_data.size():
		return schools_data[current_school_idx]["pos"]
	return Vector3.ZERO

func get_active_target_name() -> String:
	if current_state == State.AT_SPPG:
		return "SPPG (Ambil Ransum)"
	if current_school_idx < schools_data.size():
		return "%s (%d/%d)" % [schools_data[current_school_idx]["name"], current_school_idx + 1, total_schools]
	return "Selesai"

# Konsumsi bahan bakar oleh mobil saat melaju
func consume_fuel(amount: float) -> void:
	if current_state != State.DELIVERING:
		return
	current_fuel = max(0.0, current_fuel - amount)
	fuel_changed.emit(current_fuel, max_fuel)
	if current_fuel <= 0.0:
		fail_mission("Kendaraan kehabisan bahan bakar di tengah jalan! Kunjungi SPBU untuk isi bensin.")

# Pengisian bahan bakar berbayar di SPBU (2 koin per liter)
func refuel(delta: float) -> void:
	if current_fuel >= max_fuel:
		return
	if coins <= 0:
		is_refueling = false
		return
		
	var liters_to_add = 18.0 * delta
	var space = max_fuel - current_fuel
	liters_to_add = min(liters_to_add, space)
	
	fuel_buy_accumulator += liters_to_add * fuel_price_per_liter
	if fuel_buy_accumulator >= 1.0:
		var coins_to_deduct = int(fuel_buy_accumulator)
		if coins >= coins_to_deduct:
			coins -= coins_to_deduct
			fuel_buy_accumulator -= coins_to_deduct
			coins_changed.emit(coins)
			current_fuel = min(max_fuel, current_fuel + liters_to_add)
			fuel_changed.emit(current_fuel, max_fuel)
		else:
			is_refueling = false

func set_refueling(active: bool) -> void:
	is_refueling = active

# Pengiriman ke sekolah dengan POTONGAN PAJAK OTOMATIS 11%
func deliver_to_school(school_idx: int) -> void:
	if current_state != State.DELIVERING:
		return
	if school_idx != current_school_idx:
		return
	
	schools_data[school_idx]["delivered"] = true
	schools_delivered_count += 1
	
	# Sistem Upah & Pajak 11% (GDD Bab 11.2 & 11.3)
	var gross_earned = 5 # Upah kotor 5 koin per sekolah
	var tax_amount = int(round(gross_earned * tax_rate)) # 11% -> 1 koin kas kerajaan
	var net_earned = gross_earned - tax_amount # 4 koin masuk dompet pengawal
	
	total_tax_paid += tax_amount
	coins += net_earned
	coins_changed.emit(coins)
	
	var school_name = schools_data[school_idx]["name"]
	print("[KingAri] Penyerahan MBG ke %s! Upah Kotor: +%d Koin | Pajak 11%%: -%d Koin | Bersih: +%d Koin" % [school_name, gross_earned, tax_amount, net_earned])
	school_delivered.emit(school_idx, school_name, schools_delivered_count, total_schools, net_earned)
	
	if schools_delivered_count >= total_schools:
		finish_level_1()
	else:
		current_school_idx += 1

func finish_level_1() -> void:
	current_state = State.FINISHED
	var stars = 1
	if food_condition >= 80.0 and time_left >= 60.0:
		stars = 3
	elif food_condition >= 50.0:
		stars = 2
	
	var score = int(time_left * 20.0 + food_condition * 50.0 + schools_delivered_count * 200.0)
	var final_bonus = stars * 10
	coins += final_bonus
	coins_changed.emit(coins)
	
	print("[KingAri] LEVEL 1 SELESAI! Bintang: ", stars, " | Kas Pengawal: ", coins)
	mission_completed.emit(stars, score, 20 + final_bonus)

func apply_impact(speed: float) -> void:
	if current_state != State.DELIVERING:
		return
		
	var drv = get_active_driver()
	var veh = get_active_vehicle()
	var driver_decay = drv.get("decay_mult", 1.0)
	var veh_durability = veh.get("durability_mult", 1.0)
	
	# Bonus perlindungan dari upgrade armor bengkel
	var armor_bonus = 1.0 + (vehicle_upgrades["armor"] * 0.20)
	
	var base_damage = clamp((speed / 24.0) * 5.0, 2.5, 7.0)
	var final_damage = base_damage * (driver_decay / (veh_durability * armor_bonus))
	
	food_condition = max(0.0, food_condition - final_damage)
	food_changed.emit(food_condition)
	print("[KingAri] Benturan! Sisa kondisi makanan: ", int(food_condition), "% (-", snapped(final_damage, 0.1), "%)")
	if food_condition <= 0.0:
		fail_mission("Makanan hancur dan rusak berantakan! Ransum tidak layak konsumsi.")

func fail_mission(reason: String) -> void:
	current_state = State.FAILED
	print("[KingAri] MISI GAGAL: ", reason)
	mission_failed.emit(reason)
