class_name TestEconomy
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

func assert_true(condition: bool, msg: String = "") -> Dictionary:
	if not condition:
		return {"passed": false, "message": msg}
	return {"passed": true}

func assert_eq(a, b, msg: String = "") -> Dictionary:
	if a != b:
		return {"passed": false, "message": "Expected %s but got %s. %s" % [str(b), str(a), msg]}
	return {"passed": true}

func test_add_resource_increases_total() -> Dictionary:
	var initial_wood = gm.resources["wood"]
	gm.add_resource("wood", 75)
	return assert_eq(gm.resources["wood"], initial_wood + 75, "Wood should increase by 75")

func test_can_afford_checks_correctly() -> Dictionary:
	gm.resources["food"] = 100
	gm.resources["gold"] = 50
	
	var affordable = gm.can_afford({"food": 80, "gold": 40})
	if not affordable:
		return {"passed": false, "message": "Expected to afford 80 food and 40 gold"}
	
	var unaffordable = gm.can_afford({"food": 150, "gold": 50})
	if unaffordable:
		return {"passed": false, "message": "Should not be able to afford 150 food"}

	return {"passed": true}

func test_spend_resources_deducts_accurately() -> Dictionary:
	gm.resources["wood"] = 200
	gm.resources["stone"] = 100
	var ok = gm.spend_resources({"wood": 50, "stone": 40})
	if not ok:
		return {"passed": false, "message": "Spend should succeed"}
	if gm.resources["wood"] != 150 or gm.resources["stone"] != 60:
		return {"passed": false, "message": "Resources were not deducted correctly"}
	return {"passed": true}

func test_population_capacity_limits() -> Dictionary:
	gm.resources["population"] = 3
	gm.resources["max_population"] = 10
	gm.add_population(2)
	if gm.resources["population"] != 5:
		return {"passed": false, "message": "Population should be 5"}
	gm.remove_population(1)
	return assert_eq(gm.resources["population"], 4, "Population should decrease to 4")
