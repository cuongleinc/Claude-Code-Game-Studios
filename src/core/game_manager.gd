class_name GameManager
extends Node

signal resources_changed(resources: Dictionary)
signal age_advanced(new_age_name: String)
signal game_state_changed(state: String) # "playing", "victory", "defeat"
signal selection_changed(selected_objects: Array)
signal notification_posted(message: String)

enum Age {
	STONE_AGE,
	BRONZE_AGE,
	IRON_AGE,
	MEDIEVAL_AGE
}

static var instance: GameManager

var current_age: Age = Age.STONE_AGE
var age_names: Array[String] = ["Stone Age", "Bronze Age", "Iron Age", "Medieval Age"]
var age_costs: Array[Dictionary] = [
	{"food": 400, "gold": 200},
	{"food": 600, "wood": 300, "gold": 300},
	{"food": 900, "stone": 500, "gold": 500}
]
var game_state: String = "playing"


var resources: Dictionary = {
	"food": 200,
	"wood": 300,
	"stone": 150,
	"gold": 100,
	"population": 3,
	"max_population": 10
}

var selected_entities: Array = []
var active_island: int = 0 # 0 = player island, 1 = enemy island
var enemy_totem_destroyed: bool = false
var player_town_center_destroyed: bool = false

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	emit_signal("resources_changed", resources)

func add_resource(type: String, amount: int) -> void:
	if resources.has(type):
		resources[type] += amount
		emit_signal("resources_changed", resources)

func can_afford(cost: Dictionary) -> bool:
	for r in cost.keys():
		if resources.get(r, 0) < cost[r]:
			return false
	return true

func spend_resources(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for r in cost.keys():
		resources[r] -= cost[r]
	emit_signal("resources_changed", resources)
	return true

func set_population_cap(new_cap: int) -> void:
	resources["max_population"] = new_cap
	emit_signal("resources_changed", resources)

func can_add_population(count: int = 1) -> bool:
	return (resources["population"] + count) <= resources["max_population"]

func add_population(count: int = 1) -> void:
	resources["population"] = min(resources["population"] + count, resources["max_population"])
	emit_signal("resources_changed", resources)

func remove_population(count: int = 1) -> void:
	resources["population"] = max(0, resources["population"] - count)
	emit_signal("resources_changed", resources)

func can_advance_age() -> bool:
	if current_age >= Age.MEDIEVAL_AGE:
		return false
	var cost = age_costs[current_age]
	return can_afford(cost)

func get_next_age_cost() -> Dictionary:
	if current_age >= Age.MEDIEVAL_AGE:
		return {}
	return age_costs[current_age]

func advance_to_next_age() -> bool:
	if current_age >= Age.MEDIEVAL_AGE:
		post_notification("Already at maximum Age (Medieval Age)!")
		return false

	var cost = age_costs[current_age]
	if not can_afford(cost):
		var next_name = age_names[current_age + 1]
		post_notification("Insufficient resources to advance to " + next_name + "!")
		return false

	spend_resources(cost)
	current_age = (current_age + 1) as Age
	emit_signal("resources_changed", resources)
	emit_signal("age_advanced", age_names[current_age])
	post_notification("ADVANCED to the " + age_names[current_age] + "! New technologies unlocked.")
	return true


func set_game_speed(speed: float) -> void:
	Engine.time_scale = speed

func post_notification(message: String) -> void:
	emit_signal("notification_posted", message)

func trigger_victory() -> void:
	if game_state != "playing":
		return
	game_state = "victory"
	emit_signal("game_state_changed", "victory")
	post_notification("VICTORY! You have conquered the island and forged your empire!")

func trigger_defeat() -> void:
	if game_state != "playing":
		return
	game_state = "defeat"
	emit_signal("game_state_changed", "defeat")
	post_notification("DEFEAT! Your Town Center has fallen.")

func select_entity(entity: Node) -> void:
	clear_selection()
	if is_instance_valid(entity):
		selected_entities.append(entity)
		if entity.has_method("set_selected"):
			entity.set_selected(true)
		emit_signal("selection_changed", selected_entities)

func set_selection_group(entities: Array) -> void:
	clear_selection()
	for e in entities:
		if is_instance_valid(e):
			selected_entities.append(e)
			if e.has_method("set_selected"):
				e.set_selected(true)
	emit_signal("selection_changed", selected_entities)

func clear_selection() -> void:
	for e in selected_entities:
		if is_instance_valid(e) and e.has_method("set_selected"):
			e.set_selected(false)
	selected_entities.clear()
	emit_signal("selection_changed", selected_entities)
