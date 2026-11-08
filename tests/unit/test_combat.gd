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

func test_attack_animation_trigger() -> Dictionary:
	var unit = MilitaryUnit.new()
	unit.military_type = "spearman"
	unit._ready()
	unit.trigger_attack_anim()
	var anim_active = unit.is_attacking_anim
	var anim_t = unit.attack_anim_time
	unit.free()

	if not anim_active:
		return {"passed": false, "message": "Attack animation should be active"}
	if anim_t != 0.0:
		return {"passed": false, "message": "Attack animation timer should start at 0.0"}
	return {"passed": true}

func test_auto_retaliate_on_damage() -> Dictionary:
	var defender = MilitaryUnit.new()
	defender.military_type = "spearman"
	defender._ready()

	var attacker = MilitaryUnit.new()
	attacker.military_type = "corsair_raider"
	attacker._ready()

	defender.take_damage(20, attacker)
	var state_ok = defender.state == UnitBase.State.ATTACKING
	var target_ok = defender.target_entity == attacker

	defender.free()
	attacker.free()

	if not state_ok:
		return {"passed": false, "message": "Defender should switch to ATTACKING state upon being attacked"}
	if not target_ok:
		return {"passed": false, "message": "Defender should target the attacker upon retaliation"}
	return {"passed": true}

func test_slash_effect_initialization() -> Dictionary:
	var slash_script = load("res://src/combat/slash_effect.gd")
	var slash = slash_script.new()
	slash.setup(Vector3(1.0, 2.0, 3.0), Vector3.FORWARD, Color(0.2, 0.8, 1.0))
	var col_ok = slash.slash_color == Color(0.2, 0.8, 1.0)
	var spark_count = slash.sparks.size()
	slash.free()

	if not col_ok:
		return {"passed": false, "message": "Slash effect color was not set properly"}
	if spark_count != 4:
		return {"passed": false, "message": "Slash effect should spawn 4 spark debris meshes"}
	return {"passed": true}

func test_unit_death_state() -> Dictionary:
	var unit = MilitaryUnit.new()
	unit.military_type = "spearman"
	unit._ready()
	unit.die()
	var is_dying_ok = unit.is_dying
	var is_selected_ok = not unit.is_selected

	unit.free()
	if not is_dying_ok:
		return {"passed": false, "message": "Unit should enter dying state upon die()"}
	if not is_selected_ok:
		return {"passed": false, "message": "Unit selection should be cleared upon death"}
	return {"passed": true}
