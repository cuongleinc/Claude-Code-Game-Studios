class_name TestCombat
extends RefCounted

func assert_true(condition: bool, msg: String = "") -> Dictionary:
	if not condition:
		return {"passed": false, "message": msg}
	return {"passed": true}

func assert_eq(a, b, msg: String = "") -> Dictionary:
	if a != b:
		return {"passed": false, "message": "Expected %s but got %s. %s" % [str(b), str(a), msg]}
	return {"passed": true}

func test_unit_take_damage_reduces_hp() -> Dictionary:
	var unit = MilitaryUnit.new()
	unit.military_type = "spearman"
	unit._ready()
	
	var initial_hp = unit.current_hp
	unit.take_damage(30)
	var final_hp = unit.current_hp
	unit.free()

	return assert_eq(final_hp, initial_hp - 30, "HP should decrease by 30")

func test_spearman_base_stats() -> Dictionary:
	var spearman = MilitaryUnit.new()
	spearman.military_type = "spearman"
	spearman._ready()

	var hp_ok = spearman.max_hp == 130
	var dmg_ok = spearman.attack_damage == 18
	spearman.free()

	if not hp_ok:
		return {"passed": false, "message": "Spearman HP should be 130"}
	if not dmg_ok:
		return {"passed": false, "message": "Spearman attack damage should be 18"}
	return {"passed": true}

func test_catapult_high_siege_damage() -> Dictionary:
	var cat = Catapult.new()
	cat._ready()
	var dmg = cat.attack_damage
	var range_val = cat.attack_range
	cat.free()

	if dmg != 45:
		return {"passed": false, "message": "Catapult damage should be 45"}
	if range_val < 20.0:
		return {"passed": false, "message": "Catapult range should be >= 20m"}
	return {"passed": true}

func test_war_galleon_hp_and_damage() -> Dictionary:
	var galleon = WarGalleon.new()
	galleon._ready()
	var hp = galleon.max_hp
	var dmg = galleon.cannon_damage
	galleon.free()

	if hp != 550:
		return {"passed": false, "message": "War Galleon max HP should be 550"}
	if dmg != 35:
		return {"passed": false, "message": "War Galleon cannon damage should be 35"}
	return {"passed": true}

func test_projectile_initialization() -> Dictionary:
	var proj = Projectile.new()
	proj.setup(Vector3(0, 0, 0), null, 25, true)
	var is_boulder = proj.is_boulder
	var dmg = proj.damage
	proj.free()

	if not is_boulder:
		return {"passed": false, "message": "Projectile should register as boulder"}
	if dmg != 25:
		return {"passed": false, "message": "Projectile damage should be 25"}
	return {"passed": true}
