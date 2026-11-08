class_name TestFactionsAndUnits
extends RefCounted

func assert_eq(a, b, msg: String = "") -> Dictionary:
	if a != b:
		return {"passed": false, "message": "Expected %s but got %s. %s" % [str(b), str(a), msg]}
	return {"passed": true}

func test_royal_knight_stats() -> Dictionary:
	var knight = RoyalKnight.new()
	knight._ready()
	var hp = knight.max_hp
	var dmg = knight.attack_damage
	var speed = knight.move_speed
	knight.free()

	if hp != 260:
		return {"passed": false, "message": "Knight HP should be 260"}
	if dmg != 32:
		return {"passed": false, "message": "Knight damage should be 32"}
	if speed < 8.0:
		return {"passed": false, "message": "Knight speed should be >= 8.0"}
	return {"passed": true}

func test_corsair_raider_stats() -> Dictionary:
	var raider = MilitaryUnit.new()
	raider.military_type = "corsair_raider"
	raider._ready()
	var hp = raider.max_hp
	var dmg = raider.attack_damage
	var team = raider.team
	raider.free()

	if hp != 125:
		return {"passed": false, "message": "Corsair Raider HP should be 125"}
	if dmg != 20:
		return {"passed": false, "message": "Corsair Raider damage should be 20"}
	if team != "enemy":
		return {"passed": false, "message": "Corsair Raider should be on enemy team"}
	return {"passed": true}

func test_dread_captain_boss_stats() -> Dictionary:
	var captain = MilitaryUnit.new()
	captain.military_type = "dread_captain"
	captain._ready()
	var hp = captain.max_hp
	var dmg = captain.attack_damage
	var team = captain.team
	captain.free()

	if hp != 650:
		return {"passed": false, "message": "Dread Captain HP should be 650"}
	if dmg != 40:
		return {"passed": false, "message": "Dread Captain damage should be 40"}
	if team != "enemy":
		return {"passed": false, "message": "Dread Captain should be on enemy team"}
	return {"passed": true}

func test_clan_chieftain_boss_stats() -> Dictionary:
	var chief = MilitaryUnit.new()
	chief.military_type = "clan_chieftain"
	chief._ready()
	var hp = chief.max_hp
	var dmg = chief.attack_damage
	var team = chief.team
	chief.free()

	if hp != 750:
		return {"passed": false, "message": "Clan Chieftain HP should be 750"}
	if dmg != 48:
		return {"passed": false, "message": "Clan Chieftain damage should be 48"}
	if team != "enemy":
		return {"passed": false, "message": "Clan Chieftain should be on enemy team"}
	return {"passed": true}

func test_clan_berserker_stats() -> Dictionary:
	var berserker = MilitaryUnit.new()
	berserker.military_type = "clan_berserker"
	berserker._ready()
	var hp = berserker.max_hp
	var dmg = berserker.attack_damage
	berserker.free()

	if hp != 110:
		return {"passed": false, "message": "Clan Berserker HP should be 110"}
	if dmg != 18:
		return {"passed": false, "message": "Clan Berserker damage should be 18"}
	return {"passed": true}

func test_minifigure_articulated_rig_structure() -> Dictionary:
	var unit = UnitBase.new()
	unit._ready()

	var has_rig = is_instance_valid(unit.minifig_root)
	var has_hips = is_instance_valid(unit.hips_node)
	var has_legs = is_instance_valid(unit.left_leg_pivot) and is_instance_valid(unit.right_leg_pivot)
	var has_torso = is_instance_valid(unit.torso_node)
	var has_head = is_instance_valid(unit.head_node) and is_instance_valid(unit.head_stud)
	var has_arms = is_instance_valid(unit.left_arm_pivot) and is_instance_valid(unit.right_arm_pivot)
	unit.free()

	if not (has_rig and has_hips and has_legs and has_torso and has_head and has_arms):
		return {"passed": false, "message": "Minifigure rig must contain articulated hips, legs, torso, head with stud, and arm pivots"}
	return {"passed": true}

func test_minifigure_walk_locomotion_swings_pivots() -> Dictionary:
	var unit = UnitBase.new()
	unit._ready()
	unit.velocity = Vector3(5.0, 0.0, 0.0)
	unit._process_animations(0.2)

	var leg_rotated = abs(unit.left_leg_pivot.rotation.x) > 0.05 or abs(unit.right_leg_pivot.rotation.x) > 0.05
	var arm_rotated = abs(unit.left_arm_pivot.rotation.x) > 0.05 or abs(unit.right_arm_pivot.rotation.x) > 0.05
	unit.free()

	if not (leg_rotated and arm_rotated):
		return {"passed": false, "message": "Locomotion walk cycle should rotate Minifigure leg and arm joint pivots"}
	return {"passed": true}

func test_nature_tree_varieties_and_gold() -> Dictionary:
	var oak_node = ResourceNode.new()
	oak_node.setup("wood", Vector3(10, 0, 10), 200, "oak")
	var is_oak = oak_node.sub_type == "oak"
	oak_node.free()

	var palm_node = ResourceNode.new()
	palm_node.setup("wood", Vector3(30, 0, 30), 180, "palm")
	var is_palm = palm_node.sub_type == "palm"
	palm_node.free()

	var gold_node = ResourceNode.new()
	gold_node.setup("gold", Vector3(25, 0, -20), 350)
	var is_gold = gold_node.resource_type == "gold"
	gold_node.free()

	if not (is_oak and is_palm and is_gold):
		return {"passed": false, "message": "ResourceNode must properly handle oak, palm and crystalline gold assets"}
	return {"passed": true}

func test_pixel_asset_catalog_quantity() -> Dictionary:
	var dir = DirAccess.open("res://assets/pixel_art")
	if not dir:
		return {"passed": false, "message": "assets/pixel_art folder not found"}

	var count = 0
	for sub in ["characters", "environment", "items"]:
		var sdir = DirAccess.open("res://assets/pixel_art/" + sub)
		if sdir:
			sdir.list_dir_begin()
			var fn = sdir.get_next()
			while fn != "":
				if fn.ends_with(".png"):
					count += 1
				fn = sdir.get_next()

	if count < 200:
		return {"passed": false, "message": "Expected at least 200 pixel art images, found %d" % count}
	return {"passed": true}
