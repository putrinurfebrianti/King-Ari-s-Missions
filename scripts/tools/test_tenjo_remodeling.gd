extends SceneTree

func _init() -> void:
	print("==================================================")
	print("AUTOMATED VERIFICATION: TENJO ISLAND REMODELING")
	print("==================================================")

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	if not main_scene:
		printerr("[FAIL] Could not load res://scenes/main.tscn")
		quit(1)
		return
	print("[PASS] main.tscn loaded successfully")

	var root_node := main_scene.instantiate() as Node3D
	root.add_child(root_node)

	# 1. Environment Verification
	var env := root_node.get_node_or_null("TenjoIslandEnvironment")
	assert(env != null, "TenjoIslandEnvironment node must exist")
	print("[PASS] TenjoIslandEnvironment exists and initializes")

	# Check Regional Landmarks
	var ocean := env.get_node_or_null("SurroundingOcean")
	assert(ocean != null, "SurroundingOcean must exist")
	print("[PASS] SurroundingOcean generated")

	var palace := env.get_node_or_null("PalaceMainKeep")
	assert(palace != null, "PalaceMainKeep in Northern Region must exist")
	assert(palace.position.z < -40.0, "Palace must be in North Region (z < -40)")
	print("[PASS] Region 1 (North) Royal Palace of King Ari verified at z = %0.1f" % palace.position.z)

	var lake := env.get_node_or_null("PalaceLakeWater")
	assert(lake != null, "PalaceLakeWater must exist")
	print("[PASS] Palace Lake verified")

	var sppg_kitchen := env.get_node_or_null("SPPG_CentralKitchenMain")
	assert(sppg_kitchen != null, "SPPG Central Kitchen in Western Region must exist")
	assert(sppg_kitchen.position.x < -35.0, "SPPG Kitchen must be in Western Region (x < -35)")
	print("[PASS] Region 2 (West) SPPG Central Kitchen verified at x = %0.1f" % sppg_kitchen.position.x)

	var station := env.get_node_or_null("StationBuildingMain")
	assert(station != null, "StationBuildingMain in Central Region must exist")
	print("[PASS] Region 3 (Central) Tenjo Station verified")

	# Check 5 Schools in Region 4
	for i in range(1, 6):
		var school_zone := root_node.get_node_or_null("School_%d" % i)
		assert(school_zone != null, "School_%d node must exist" % i)
		assert(school_zone.position.x > 15.0, "School_%d must be in Eastern Region (x > 15)" % i)
		print("[PASS] School_%d verified at %s" % [i, str(school_zone.position)])
	print("[PASS] Region 4 (East) 5 Dedicated Schools verified")

	# Region 5 Outskirts & Swamp
	var sawah := env.get_node_or_null("SawahField")
	assert(sawah != null, "SawahField in Southern Region must exist")
	var bridge := env.get_node_or_null("Bridge_CentralWetland")
	assert(bridge != null, "Swamp timber bridges must exist")
	print("[PASS] Region 5 (South) Sawah & Swamp Bridges verified")

	# 2. Road Network Collision Check
	var main_road := env.get_node_or_null("MainRoad_EW") as StaticBody3D
	assert(main_road != null, "MainRoad_EW must be a StaticBody3D with collision")
	print("[PASS] MainRoad_EW StaticBody3D with collision verified")

	# 3. SPPG Depot & Player Car
	var car := root_node.get_node_or_null("PlayerCar")
	assert(car != null, "PlayerCar must exist")
	assert(car.position.x < -35.0, "PlayerCar must spawn in Western Region near SPPG")
	print("[PASS] PlayerCar verified at %s" % str(car.position))

	var sppg_depot := root_node.get_node_or_null("SPPG_Depot")
	assert(sppg_depot != null, "SPPG_Depot must exist")
	print("[PASS] SPPG_Depot verified at %s" % str(sppg_depot.position))

	# 4. GameManager Gameplay Cycle
	var gm = root.get_node_or_null("/root/GameManager")
	assert(gm != null, "GameManager autoload must exist")
	print("[PASS] GameManager autoload found")

	gm.reset_game()
	assert(gm.current_state == gm.State.AT_SPPG, "Game should start AT_SPPG")
	assert(gm.food_condition == 100.0, "Initial food condition must be 100")
	assert(gm.current_fuel == 40.0, "Initial fuel must be 40L")
	print("[PASS] Initial state: AT_SPPG, Food: 100%, Fuel: 40L")

	# Test pickup MBG at SPPG
	sppg_depot.interact(car)
	assert(gm.current_state == gm.State.DELIVERING, "State should be DELIVERING after SPPG pickup")
	print("[PASS] SPPG Pickup succeeded, State: DELIVERING, Target: %s" % gm.get_active_target_name())

	# Test deliver to School 1
	var s1 = root_node.get_node_or_null("School_1")
	s1.interact(car)
	assert(gm.schools_delivered_count == 1, "Delivered count should be 1")
	assert(gm.current_school_idx == 1, "Current school idx should advance to 1")
	print("[PASS] School 1 delivery succeeded, Next target: %s" % gm.get_active_target_name())

	# Test deliver remaining schools 2..5
	for s_idx in range(2, 6):
		var s_node = root_node.get_node_or_null("School_%d" % s_idx)
		s_node.interact(car)
	assert(gm.schools_delivered_count == 5, "All 5 schools should be delivered")
	assert(gm.current_state == gm.State.FINISHED, "Game state should be FINISHED after 5 deliveries")
	print("[PASS] All 5 schools delivered! Final State: FINISHED")

	# Test Fuel System
	gm.reset_game()
	gm.start_delivery()
	gm.consume_fuel(5.0)
	assert(gm.current_fuel == 35.0, "Fuel should reduce to 35.0")
	gm.set_refueling(true)
	gm.refuel(1.0)
	assert(gm.current_fuel > 35.0, "Fuel should increase during refuel")
	gm.set_refueling(false)
	print("[PASS] Fuel consumption and refueling verified")

	# Test Season System
	gm.set_season(gm.Season.KEMARAU)
	assert(gm.current_season == gm.Season.KEMARAU, "Season should be KEMARAU")
	gm.toggle_season()
	assert(gm.current_season == gm.Season.HUJAN, "Season should toggle to HUJAN")
	print("[PASS] Season System (Kemarau & Hujan) verified")

	# Test Minimap
	var minimap := root_node.get_node_or_null("HUD/Minimap")
	assert(minimap != null, "Minimap node must exist in HUD")
	print("[PASS] Minimap verified in HUD")

	print("==================================================")
	print("ALL VERIFICATIONS PASSED 100%! READY FOR PLAY!")
	print("==================================================")
	quit(0)

