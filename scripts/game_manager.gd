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

enum State { AT_SPPG, DELIVERING, FINISHED, FAILED }
var current_state: State = State.AT_SPPG

enum Season { KEMARAU, HUJAN }
var current_season: Season = Season.KEMARAU

var food_condition: float = 100.0
var total_time: float = 300.0
var time_left: float = total_time # 5 Menit sesuai GDD Titah Pertama Raja Ari

# Sistem Bahan Bakar (GDD Bab 5.4 & 10.2: 40 Liter Kapasitas)
var max_fuel: float = 40.0
var current_fuel: float = 40.0
var is_refueling: bool = false

# Sistem Koin & Metagame (Upah 5 koin per sekolah)
var coins: int = 50
var selected_driver_id: String = "fatur"
var selected_vehicle_id: String = "van_standard"
var owned_vehicles: Array[String] = ["van_standard"]

const SCHOOL_NAME_POOL: Array[String] = [
	"SD Negeri Harapan Bangsa",
	"SD Cendekia Nusantara",
	"SD Pelita Generasi",
	"SD Tunas Pertiwi",
	"SD Bintang Mulia",
	"SD Mentari Ceria",
	"SD Cahaya Insani",
	"SD Bina Prestasi",
	"SD Pusaka Bangsa",
	"SD Tunas Harapan",
	"SMP Negeri 1 Sukamaju",
	"SMP Citra Mandiri",
	"SMP Bina Karya",
	"SMP Tunas Bangsa",
	"SMP Dharma Persada",
	"SMP Generasi Emas",
	"SMP Pelita Nusantara",
	"SMP Pertiwi Mandiri",
	"SMP Cakrawala Ilmu",
	"SMP Bintang Pendidikan",
	"SMA Negeri 1 Sukamaju",
	"SMA Garuda Nusantara",
	"SMA Cendekia Utama",
	"SMA Bina Prestasi",
	"SMA Pelita Bangsa",
	"SMA Dharma Bakti",
	"SMA Pusaka Indonesia",
	"SMA Generasi Mandiri",
	"SMA Citra Bangsa",
	"SMA Bintang Persada",
	"SD Mutiara Ilmu",
	"SD Angkasa Ceria",
	"SD Taman Ilmu",
	"SMP Cakra Buana",
	"SMP Wijaya Kusuma",
	"SMP Mutiara Bangsa",
	"SMA Adi Karya",
	"SMA Cakrawala Bangsa",
	"SMA Nusantara Jaya",
	"SMA Wijaya Mandiri",
	"SD Karya Gemilang",
	"SD Bumi Cendekia",
	"SMP Lentera Pendidikan",
	"SMP Karya Nusantara",
	"SMP Bhakti Mulia",
	"SMA Lentera Harapan",
	"SMA Karya Gemilang",
	"SMA Bumi Persada",
	"SMA Tunas Cendekia",
	"SMA Mandala Bangsa"
]

# Lima lokasi tujuan di peta; nama sekolah dipilih acak untuk setiap misi.
var schools_data: Array[Dictionary] = [
	{
		"id": 0,
		"name": "SDN 01 Tenjo",
		"short_name": "SDN 01",
		"pos": Vector3(52.0, 0.15, -2.0),
		"delivered": false
	},
	{
		"id": 1,
		"name": "SDN 02 Harapan",
		"short_name": "SDN 02",
		"pos": Vector3(-28.0, 0.15, 30.0),
		"delivered": false
	},
	{
		"id": 2,
		"name": "SMPN 01 Nusa",
		"short_name": "SMPN 01",
		"pos": Vector3(36.0, 0.15, 30.0),
		"delivered": false
	},
	{
		"id": 3,
		"name": "SDN 03 Garuda",
		"short_name": "SDN 03",
		"pos": Vector3(0.0, 0.15, -42.0),
		"delivered": false
	},
	{
		"id": 4,
		"name": "Madrasah Tenjo",
		"short_name": "Madrasah",
		"pos": Vector3(58.0, 0.15, 12.0),
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

# Database Armada Mobil MBG Resmi
var vehicle_catalog: Dictionary = {
	"van_standard": {
		"id": "van_standard",
		"name": "Van MBG Dinas Kerajaan",
		"price": 0,
		"thumb_path": "res://assets/textures/ui/vehicle_van.png",
		"desc": "Kendaraan dinas MBG standar berpelat resmi istana. Seimbang dan handal untuk pemula.",
		"speed_mult": 1.0,
		"accel_mult": 1.0,
		"durability_mult": 1.0
	},
	"pickup_express": {
		"id": "pickup_express",
		"name": "Pick-Up MBG Patroli Cepat",
		"price": 80,
		"thumb_path": "res://assets/textures/ui/vehicle_pickup.png",
		"desc": "Armada pick-up MBG resmi bertenaga turbo (+25% akselerasi) untuk menembus rute terjal.",
		"speed_mult": 1.15,
		"accel_mult": 1.25,
		"durability_mult": 0.9
	},
	"truck_heavy": {
		"id": "truck_heavy",
		"name": "Truk MBG Armor Heavy-Duty",
		"price": 180,
		"thumb_path": "res://assets/textures/ui/vehicle_truck.png",
		"desc": "Armada boks berpelindung baja anti-guncangan (+50% ketahanan ransum) mandat istana.",
		"speed_mult": 1.10,
		"accel_mult": 0.95,
		"durability_mult": 1.5
	}
}

func _ready() -> void:
	randomize()
	reset_game()

func _process(delta: float) -> void:
	if current_state == State.DELIVERING:
		time_left = maxf(time_left - delta, 0.0)
		time_changed.emit(time_left)
		if time_left <= 0.0:
			fail_mission("Waktu habis (05:00)! Bel sekolah telah berbunyi sebelum seluruh makanan terkirim.")
			return
			
		# Konsumsi bahan bakar saat kendaraan berjalan
		if is_refueling:
			refuel(delta)

func reset_game() -> void:
	current_state = State.AT_SPPG
	food_condition = 100.0
	time_left = total_time
	current_fuel = max_fuel
	is_refueling = false
	current_school_idx = 0
	schools_delivered_count = 0
	_randomize_school_route()
	
	for i in range(schools_data.size()):
		schools_data[i]["delivered"] = false
		
	food_changed.emit(food_condition)
	time_changed.emit(time_left)
	fuel_changed.emit(current_fuel, max_fuel)

func _randomize_school_route() -> void:
	var available_names := SCHOOL_NAME_POOL.duplicate()
	available_names.shuffle()
	total_schools = schools_data.size()

	for i in range(total_schools):
		var school_name: String = available_names[i]
		schools_data[i]["name"] = school_name
		schools_data[i]["short_name"] = _get_short_school_name(school_name)

func _get_short_school_name(school_name: String) -> String:
	var short_name := school_name
	if short_name.begins_with("SD Negeri "):
		short_name = short_name.replace("SD Negeri ", "SDN ")
	elif short_name.begins_with("SMP Negeri "):
		short_name = short_name.replace("SMP Negeri ", "SMPN ")
	elif short_name.begins_with("SMA Negeri "):
		short_name = short_name.replace("SMA Negeri ", "SMAN ")

	if short_name.length() > 19:
		short_name = short_name.substr(0, 18) + ".."
	return short_name

func set_season(new_season: Season) -> void:
	current_season = new_season
	season_changed.emit(int(current_season))

func toggle_season() -> void:
	if current_season == Season.KEMARAU:
		set_season(Season.HUJAN)
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

func start_delivery() -> void:
	if current_state == State.AT_SPPG:
		current_state = State.DELIVERING
		food_condition = 100.0
		time_left = total_time
		current_fuel = max_fuel
		current_school_idx = 0
		schools_delivered_count = 0
		food_changed.emit(food_condition)
		time_changed.emit(time_left)
		fuel_changed.emit(current_fuel, max_fuel)
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

func get_school_route_text() -> String:
	var route: Array[String] = []
	for i in range(schools_data.size()):
		route.append("%d. %s" % [i + 1, schools_data[i]["name"]])
	return "\n".join(route)

# Konsumsi bahan bakar oleh mobil saat melaju
func consume_fuel(amount: float) -> void:
	if current_state != State.DELIVERING:
		return
	current_fuel = max(0.0, current_fuel - amount)
	fuel_changed.emit(current_fuel, max_fuel)
	if current_fuel <= 0.0:
		fail_mission("Kendaraan kehabisan bahan bakar di tengah jalan! Kunjungi SPBU untuk isi bensin.")

# Pengisian bahan bakar di SPBU
func refuel(delta: float) -> void:
	if current_fuel < max_fuel:
		current_fuel = min(max_fuel, current_fuel + 18.0 * delta)
		fuel_changed.emit(current_fuel, max_fuel)

func set_refueling(active: bool) -> void:
	is_refueling = active

# Pengiriman ke sekolah (GDD Bab 11.2: Upah 5 Koin per Sekolah)
func deliver_to_school(school_idx: int) -> void:
	if current_state != State.DELIVERING:
		return
	if school_idx < 0 or school_idx >= schools_data.size():
		push_error("Indeks sekolah tidak valid: %d" % school_idx)
		return
	if school_idx != current_school_idx:
		return # Harus sesuai urutan rute atau sekolah aktif
	
	schools_data[school_idx]["delivered"] = true
	schools_delivered_count += 1
	var earned = 5 # Upah 5 koin per sekolah sesuai GDD Bab 11.2
	coins += earned
	coins_changed.emit(coins)
	
	var school_name = schools_data[school_idx]["name"]
	print("[KingAri] Berhasil menyerahkan MBG ke %s! Upah: +%d Koin." % [school_name, earned])
	var all_schools_delivered = schools_delivered_count >= total_schools
	if not all_schools_delivered:
		current_school_idx += 1
	school_delivered.emit(school_idx, school_name, schools_delivered_count, total_schools, earned)
	
	if all_schools_delivered:
		# Seluruh 5 sekolah berhasil dikirimi makanan!
		finish_level_1()

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
	
	print("[KingAri] LEVEL 1 SELESAI! Seluruh 5 Sekolah Sukses Dikirimkan. Bintang: ", stars)
	mission_completed.emit(stars, score, 25 + final_bonus)

func apply_impact(speed: float) -> void:
	if current_state != State.DELIVERING:
		return
		
	var drv = get_active_driver()
	var veh = get_active_vehicle()
	var driver_decay = drv.get("decay_mult", 1.0)
	var veh_durability = veh.get("durability_mult", 1.0)
	
	var base_damage = clamp((speed / 24.0) * 5.0, 2.5, 7.0)
	var final_damage = base_damage * (driver_decay / veh_durability)
	
	food_condition = max(0.0, food_condition - final_damage)
	food_changed.emit(food_condition)
	print("[KingAri] Benturan! Sisa kondisi makanan: ", int(food_condition), "% (-", snapped(final_damage, 0.1), "%)")
	if food_condition <= 0.0:
		fail_mission("Makanan hancur dan rusak berantakan! Ransum tidak layak konsumsi.")

func fail_mission(reason: String) -> void:
	if current_state != State.DELIVERING:
		return
	current_state = State.FAILED
	print("[KingAri] MISI GAGAL: ", reason)
	mission_failed.emit(reason)
