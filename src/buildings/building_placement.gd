class_name BuildingPlacement
extends Node3D

signal building_placed(type: String, world_pos: Vector3)

var is_placing: bool = false
var current_type: String = ""
var ghost_node: Node3D
var ghost_mat: StandardMaterial3D
var island_world: IslandWorld

func _ready() -> void:
	ghost_mat = StandardMaterial3D.new()
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.6)
	ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func start_placement(type: String) -> void:
	if not BuildingData.BUILDINGS.has(type):
		return
	if is_placing:
		cancel_placement()

	current_type = type
	is_placing = true

	var data = BuildingData.BUILDINGS[type]
	var b_size: Vector3 = data.get("size", Vector3(2.5, 2.0, 2.5))

	ghost_node = Node3D.new()
	ghost_node.name = "Ghost"
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = b_size
	mesh_inst.mesh = box
	mesh_inst.material_override = ghost_mat
	mesh_inst.position = Vector3(0.0, b_size.y * 0.5, 0.0)
	ghost_node.add_child(mesh_inst)
	add_child(ghost_node)

func cancel_placement() -> void:
	is_placing = false
	current_type = ""
	if is_instance_valid(ghost_node):
		ghost_node.queue_free()
		ghost_node = null

func update_ghost_position(world_pos: Vector3) -> void:
	if not is_placing or not is_instance_valid(ghost_node):
		return

	# Grid snap (1 meter snap)
	var snapped_pos = Vector3(round(world_pos.x), 0.5, round(world_pos.z))
	ghost_node.global_position = snapped_pos

	var valid = is_valid_placement(snapped_pos)
	if valid:
		ghost_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.6) # Green
	else:
		ghost_mat.albedo_color = Color(0.9, 0.2, 0.2, 0.6) # Red

func is_valid_placement(pos: Vector3) -> bool:
	if not island_world:
		return true

	if current_type == "harbor":
		# Harbor must be near player island coast
		var dist = pos.distance_to(island_world.island1_center)
		return dist >= (island_world.island1_radius - 6.0) and dist <= (island_world.island1_radius + 4.0)

	# Other buildings must be within player island
	return island_world.is_on_player_island(pos)

func try_place(world_pos: Vector3) -> bool:
	if not is_placing:
		return false

	var snapped_pos = Vector3(round(world_pos.x), 0.5, round(world_pos.z))
	if not is_valid_placement(snapped_pos):
		if GameManager.instance:
			GameManager.instance.post_notification("Cannot build here! Location invalid.")
		return false

	var data = BuildingData.BUILDINGS[current_type]
	var cost = data.get("cost", {})
	if GameManager.instance:
		if not GameManager.instance.can_afford(cost):
			GameManager.instance.post_notification("Not enough resources to construct " + data["name"])
			return false
		GameManager.instance.spend_resources(cost)

	emit_signal("building_placed", current_type, snapped_pos)
	cancel_placement()
	return true
