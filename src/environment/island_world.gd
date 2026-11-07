class_name IslandWorld
extends Node3D

@export var water_mesh_size: float = 300.0

var island1_center: Vector3 = Vector3(-25.0, 0.0, 0.0)
var island1_radius: float = 24.0

var island2_center: Vector3 = Vector3(45.0, 0.0, 0.0)
var island2_radius: float = 22.0

func _ready() -> void:
	build_ocean()
	build_island(island1_center, island1_radius, Color(0.28, 0.65, 0.28), Color(0.85, 0.78, 0.52))
	build_island(island2_center, island2_radius, Color(0.35, 0.45, 0.32), Color(0.72, 0.65, 0.48))
	spawn_initial_resources()

func build_ocean() -> void:
	var ocean_mesh = PlaneMesh.new()
	ocean_mesh.size = Vector2(water_mesh_size, water_mesh_size)
	ocean_mesh.subdivide_width = 80
	ocean_mesh.subdivide_depth = 80

	var ocean_mat = ShaderMaterial.new()
	ocean_mat.shader = preload("res://src/environment/water.gdshader")

	var ocean_instance = MeshInstance3D.new()
	ocean_instance.name = "Ocean"
	ocean_instance.mesh = ocean_mesh
	ocean_instance.material_override = ocean_mat
	ocean_instance.position = Vector3(0.0, 0.0, 0.0)
	add_child(ocean_instance)

func build_island(center: Vector3, radius: float, grass_col: Color, sand_col: Color) -> void:
	# 1. Sand base
	var sand_mesh = CylinderMesh.new()
	sand_mesh.top_radius = radius
	sand_mesh.bottom_radius = radius + 3.0
	sand_mesh.height = 1.0

	var sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = sand_col
	sand_mat.roughness = 0.9

	var sand_node = MeshInstance3D.new()
	sand_node.mesh = sand_mesh
	sand_node.material_override = sand_mat
	sand_node.position = center + Vector3(0.0, 0.1, 0.0)
	add_child(sand_node)

	# Static collision for sand
	var sand_body = StaticBody3D.new()
	var sand_col_shape = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = radius
	cyl_shape.height = 1.0
	sand_col_shape.shape = cyl_shape
	sand_body.add_child(sand_col_shape)
	sand_node.add_child(sand_body)

	# 2. Raised Grass Plateau
	var grass_mesh = CylinderMesh.new()
	grass_mesh.top_radius = radius * 0.82
	grass_mesh.bottom_radius = radius * 0.88
	grass_mesh.height = 0.6

	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = grass_col
	grass_mat.roughness = 0.85

	var grass_node = MeshInstance3D.new()
	grass_node.mesh = grass_mesh
	grass_node.material_override = grass_mat
	grass_node.position = center + Vector3(0.0, 0.5, 0.0)
	add_child(grass_node)

func spawn_initial_resources() -> void:
	var res_container = Node3D.new()
	res_container.name = "ResourceNodes"
	add_child(res_container)

	# Trees on Island 1
	var tree_offsets = [
		Vector3(-8.0, 0.8, -8.0),
		Vector3(-12.0, 0.8, -5.0),
		Vector3(-14.0, 0.8, -10.0),
		Vector3(-6.0, 0.8, -12.0),
		Vector3(-10.0, 0.8, 8.0),
		Vector3(-15.0, 0.8, 6.0),
		Vector3(-8.0, 0.8, 12.0)
	]
	for off in tree_offsets:
		spawn_resource(res_container, "wood", island1_center + off, 150)

	# Stone Rocks
	var stone_offsets = [
		Vector3(8.0, 0.8, -10.0),
		Vector3(12.0, 0.8, -7.0),
		Vector3(14.0, 0.8, -12.0),
		Vector3(10.0, 0.8, 11.0)
	]
	for off in stone_offsets:
		spawn_resource(res_container, "stone", island1_center + off, 200)

	# Berry Bushes (Food)
	var food_offsets = [
		Vector3(-5.0, 0.8, 6.0),
		Vector3(-3.0, 0.8, 9.0),
		Vector3(-6.0, 0.8, 10.0)
	]
	for off in food_offsets:
		spawn_resource(res_container, "food", island1_center + off, 120)

	# Gold Veins
	var gold_offsets = [
		Vector3(11.0, 0.8, 6.0),
		Vector3(13.0, 0.8, 8.0)
	]
	for off in gold_offsets:
		spawn_resource(res_container, "gold", island1_center + off, 250)

	# Enemy Island Resources (Trees & Stone)
	var enemy_trees = [
		Vector3(-8.0, 0.8, -6.0),
		Vector3(-10.0, 0.8, 5.0),
		Vector3(6.0, 0.8, -8.0),
		Vector3(9.0, 0.8, 7.0)
	]
	for off in enemy_trees:
		spawn_resource(res_container, "wood", island2_center + off, 150)

func spawn_resource(parent: Node3D, type: String, pos: Vector3, amount: int) -> void:
	var node = Node3D.new()
	node.set_script(preload("res://src/economy/resource_node.gd"))
	parent.add_child(node)
	node.call("setup", type, pos, amount)


func is_on_player_island(pos: Vector3) -> bool:
	return pos.distance_to(island1_center) <= island1_radius

func is_on_enemy_island(pos: Vector3) -> bool:
	return pos.distance_to(island2_center) <= island2_radius

func is_on_any_island(pos: Vector3) -> bool:
	return is_on_player_island(pos) or is_on_enemy_island(pos)
