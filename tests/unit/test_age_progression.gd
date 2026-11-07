class_name TestAgeProgression
extends RefCounted

var gm: GameManager

func setup() -> void:
	gm = GameManager.new()
	GameManager.instance = gm
	gm._ready()

func teardown() -> void:
	if gm:
		gm.free()
		GameManager.instance = null

func assert_eq(a, b, msg: String = "") -> Dictionary:
	if a != b:
		return {"passed": false, "message": "Expected %s but got %s. %s" % [str(b), str(a), msg]}
	return {"passed": true}

func test_starts_in_stone_age() -> Dictionary:
	return assert_eq(gm.current_age, GameManager.Age.STONE_AGE, "Empire should start in Stone Age")

func test_advancement_requires_exact_costs() -> Dictionary:
	gm.resources["food"] = 100
	gm.resources["gold"] = 50
	var can_adv = gm.can_advance_age()
	if can_adv:
		return {"passed": false, "message": "Should not advance without 400 Food and 200 Gold"}
	
	gm.resources["food"] = 400
	gm.resources["gold"] = 200
	if not gm.can_advance_age():
		return {"passed": false, "message": "Should be able to advance with 400 Food and 200 Gold"}
	return {"passed": true}

func test_advances_through_bronze_iron_medieval() -> Dictionary:
	# Give abundant resources
	gm.resources["food"] = 3000
	gm.resources["wood"] = 3000
	gm.resources["stone"] = 3000
	gm.resources["gold"] = 3000

	# Advance to Bronze Age
	var ok1 = gm.advance_to_next_age()
	if not ok1 or gm.current_age != GameManager.Age.BRONZE_AGE:
		return {"passed": false, "message": "Failed to advance to Bronze Age"}

	# Advance to Iron Age
	var ok2 = gm.advance_to_next_age()
	if not ok2 or gm.current_age != GameManager.Age.IRON_AGE:
		return {"passed": false, "message": "Failed to advance to Iron Age"}

	# Advance to Medieval Age
	var ok3 = gm.advance_to_next_age()
	if not ok3 or gm.current_age != GameManager.Age.MEDIEVAL_AGE:
		return {"passed": false, "message": "Failed to advance to Medieval Age"}

	# Attempt to advance past Medieval Age (should be blocked)
	var ok4 = gm.advance_to_next_age()
	if ok4:
		return {"passed": false, "message": "Should not be able to advance past Medieval Age"}

	return {"passed": true}
