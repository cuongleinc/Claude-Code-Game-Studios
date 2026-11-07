class_name BuildingBase
extends Node3D

signal building_completed(building: BuildingBase)
signal building_destroyed(building: BuildingBase)
signal unit_trained(unit_type: String, spawn_pos: Vector3)

@export var building_type: String = "house"
@export var team: String = "player" # "player" or "enemy"
@export var current_hp: int = 250
@export var max_hp: int = 250
@export var is_constructed: bool = true
@export var construction_progress: float = 1.0

var is_selected: bool = false
var selection_ring: MeshInstance3D
var visual_mesh: Node3D
var training_queue: Array[String] = []
var training_timer: float = 0.0
var training_time_required: float = 4.0
var farm_timer: float = 0.0

func setup(type: String, pos: Vector3, p_team: String = "player", constructed: bool = true) -> void:
	building_type = type
	team = p_team
	if is_inside_tree():
		global_position = pos
	else:
		position = pos
	is_constructed = constructed


	var data = BuildingData.BUILDINGS.get(type, {})
	max_hp = data.get("hp", 300)
	current_hp = max_hp

	build_visual()
	build_collision()
	build_selection_ring()

	if is_constructed and team == "player":
		apply_completion_effects()

func build_visual() -> void:
	visual_mesh = Node3D.new()
	visual_mesh.name = "Visual"
	add_child(visual_mesh)

	var data = BuildingData.BUILDINGS.get(building_type, {})
	var b_size: Vector3 = data.get("size", Vector3(2.5, 2.0, 2.5))
	var base_col: Color = data.get("color", Color(0.7, 0.6, 0.5))
	if team == "enemy":
		base_col = Color(0.65, 0.25, 0.22)

	# Main Structure
	var body_mesh = BoxMesh.new()
	body_mesh.size = b_size
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = base_col
	body_mat.roughness = 0.75

	var body_node = MeshInstance3D.new()
	body_node.mesh = body_mesh
	body_node.material_override = body_mat
	body_node.position = Vector3(0.0, b_size.y * 0.5, 0.0)
	visual_mesh.add_child(body_node)

	# Roof for houses, town center, barracks
	if building_type in ["house", "town_center", "barracks"]:
		var roof_mesh = PrismMesh.new()
		roof_mesh.size = Vector3(b_size.x * 1.15, 1.2, b_size.z * 1.1)
		var roof_mat = StandardMaterial3D.new()
		roof_mat.albedo_color = Color(0.48, 0.22, 0.15) if team == "player" else Color(0.3, 0.15, 0.15)
		var roof_node = MeshInstance3D.new()
		roof_node.mesh = roof_mesh
		roof_node.material_override = roof_mat
		roof_node.position = Vector3(0.0, b_size.y + 0.6, 0.0)
		visual_mesh.add_child(roof_node)

	# Special Harbor Dock Extension
	if building_type == "harbor":
		var dock_mesh = BoxMesh.new()
		dock_mesh.size = Vector3(2.0, 0.3, 4.0)
		var dock_mat = StandardMaterial3D.new()
		dock_mat.albedo_color = Color(0.42, 0.28, 0.18)
		var dock_node = MeshInstance3D.new()
		dock_node.mesh = dock_mesh
		dock_node.material_override = dock_mat
		dock_node.position = Vector3(b_size.x * 0.5 + 1.0, 0.15, 0.0)
		visual_mesh.add_child(dock_node)

func build_collision() -> void:
	var data = BuildingData.BUILDINGS.get(building_type, {})
	var b_size: Vector3 = data.get("size", Vector3(2.5, 2.0, 2.5))

	var body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = b_size + Vector3(0.4, 0.5, 0.4)
	col.shape = box_shape
	col.position = Vector3(0.0, b_size.y * 0.5, 0.0)
	body.add_child(col)
	body.set_meta("entity", self)
	add_child(body)

func build_selection_ring() -> void:
	var data = BuildingData.BUILDINGS.get(building_type, {})
	var b_size: Vector3 = data.get("size", Vector3(2.5, 2.0, 2.5))
	var radius = max(b_size.x, b_size.z) * 0.75

	selection_ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = radius - 0.15
	torus.outer_radius = radius
	selection_ring.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0) if team == "player" else Color(1.0, 0.2, 0.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_ring.material_override = mat
	selection_ring.position = Vector3(0.0, 0.1, 0.0)
	selection_ring.visible = false
	add_child(selection_ring)

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selection_ring:
		selection_ring.visible = selected

func apply_completion_effects() -> void:
	var data = BuildingData.BUILDINGS.get(building_type, {})
	var pop_bonus = data.get("pop_bonus", 0)
	if pop_bonus > 0 and GameManager.instance:
		GameManager.instance.set_population_cap(GameManager.instance.resources["max_population"] + pop_bonus)

func _process(delta: float) -> void:
	if not is_constructed:
		return

	# Farm generates food passively
	if building_type == "farm" and team == "player":
		farm_timer += delta
		if farm_timer >= 3.0:
			farm_timer = 0.0
			if GameManager.instance:
				GameManager.instance.add_resource("food", 5)

	# Unit training queue
	if training_queue.size() > 0:
		training_timer += delta
		if training_timer >= training_time_required:
			training_timer = 0.0
			var trained = training_queue.pop_front()
			var spawn_offset = Vector3(3.0, 0.5, 0.0)
			emit_signal("unit_trained", trained, global_position + spawn_offset)

func queue_unit(type: String) -> bool:
	if not GameManager.instance:
		return false

	var cost = {}
	match type:
		"villager":
			cost = {"food": 50}
		"spearman":
			cost = {"food": 60, "wood": 30}
		"archer":
			cost = {"food": 50, "wood": 50}
		"transport_ship":
			cost = {"wood": 120, "gold": 40}

	if not GameManager.instance.can_afford(cost):
		GameManager.instance.post_notification("Not enough resources to train " + type.capitalize())
		return false

	if type != "transport_ship" and not GameManager.instance.can_add_population(1):
		GameManager.instance.post_notification("Population cap reached! Build houses.")
		return false

	GameManager.instance.spend_resources(cost)
	if type != "transport_ship":
		GameManager.instance.add_population(1)

	training_queue.append(type)
	GameManager.instance.post_notification("Training " + type.capitalize() + "...")
	return true

func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		die()

func die() -> void:
	emit_signal("building_destroyed", self)
	if building_type == "town_center" and team == "player" and GameManager.instance:
		GameManager.instance.trigger_defeat()
	elif building_type == "totem_shrine" and team == "enemy" and GameManager.instance:
		GameManager.instance.trigger_victory()
	queue_free()
