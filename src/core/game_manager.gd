class_name GameManager
extends Node

signal resources_changed(resources: Dictionary)
signal age_advanced(new_age_name: String)
signal game_state_changed(state: String) # "playing", "victory", "defeat"
signal selection_changed(selected_objects: Array)
signal notification_posted(message: String)

enum Age {
	STONE_AGE,
	BRONZE_AGE
}

static var instance: GameManager

var current_age: Age = Age.STONE_AGE
var age_names: Array[String] = ["Stone Age", "Bronze Age"]
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
	if current_age == Age.BRONZE_AGE:
		return false
	return resources["food"] >= 400 and resources["gold"] >= 200

func advance_to_bronze_age() -> bool:
	if not can_advance_age():
		post_notification("Need 400 Food and 200 Gold to advance to Bronze Age!")
		return false
	resources["food"] -= 400
	resources["gold"] -= 200
	current_age = Age.BRONZE_AGE
	emit_signal("resources_changed", resources)
	emit_signal("age_advanced", age_names[current_age])
	post_notification("Advanced to the Bronze Age! Bronze barracks and spearmen unlocked.")
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
