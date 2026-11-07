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
