class_name IslandWorld
extends Node3D

@export var water_mesh_size: float = 600.0

# Doubled Island Dimensions
var island1_center: Vector3 = Vector3(-50.0, 0.0, 0.0)
var island1_radius: float = 50.0

var island2_center: Vector3 = Vector3(90.0, 0.0, 0.0)
var island2_radius: float = 45.0

func _ready() -> void:
	build_ocean()
	build_player_island()
	build_enemy_island()
	spawn_initial_resources()
	spawn_scenic_landmarks()

func build_ocean() -> void:
	var ocean_mesh = PlaneMesh.new()
	ocean_mesh.size = Vector2(water_mesh_size, water_mesh_size)
	ocean_mesh.subdivide_width = 100
	ocean_mesh.subdivide_depth = 100

	var ocean_mat = ShaderMaterial.new()
	ocean_mat.shader = preload("res://src/environment/water.gdshader")

	var ocean_instance = MeshInstance3D.new()
	ocean_instance.name = "Ocean"
	ocean_instance.mesh = ocean_mesh
	ocean_instance.material_override = ocean_mat
	ocean_instance.position = Vector3(0.0, 0.0, 0.0)
	add_child(ocean_instance)

func build_player_island() -> void:
	# 1. Broad Sand Beach Base (Radius 50m)
	var sand_mesh = CylinderMesh.new()
	sand_mesh.top_radius = island1_radius
	sand_mesh.bottom_radius = island1_radius + 5.0
	sand_mesh.height = 1.0

	var sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.88, 0.82, 0.58)
	sand_mat.roughness = 0.9

	var sand_node = MeshInstance3D.new()
	sand_node.mesh = sand_mesh
	sand_node.material_override = sand_mat
	sand_node.position = island1_center + Vector3(0.0, 0.1, 0.0)
	add_child(sand_node)

	# Static collision for entire island footprint
	var sand_body = StaticBody3D.new()
	var sand_col_shape = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = island1_radius
	cyl_shape.height = 1.0
	sand_col_shape.shape = cyl_shape
	sand_body.add_child(sand_col_shape)
	sand_node.add_child(sand_body)

	# 2. Main Lush Emerald Grass Plateau (Radius 42m) with MCP Terrain Grass Texture
	var grass_mesh = CylinderMesh.new()
	grass_mesh.top_radius = island1_radius * 0.84
	grass_mesh.bottom_radius = island1_radius * 0.89
	grass_mesh.height = 0.6

	var grass_mat = StandardMaterial3D.new()
	var grass_tex_path = "res://assets/environment/terrain_grass.png"
	if ResourceLoader.exists(grass_tex_path):
		var tex = load(grass_tex_path)
		grass_mat.albedo_texture = tex
		grass_mat.uv1_scale = Vector3(16.0, 16.0, 1.0)
		grass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	else:
		grass_mat.albedo_color = Color(0.24, 0.62, 0.22)
	grass_mat.roughness = 0.85

	var grass_node = MeshInstance3D.new()
	grass_node.mesh = grass_mesh
	grass_node.material_override = grass_mat
	grass_node.position = island1_center + Vector3(0.0, 0.5, 0.0)
	add_child(grass_node)

	# 3. Elevated Resource-Rich Mountain Quarry & Mining Plateau (North-East)
	var quarry_center = island1_center + Vector3(24.0, 0.0, -18.0)
	var quarry_radius = 18.0
	var quarry_mesh = CylinderMesh.new()
	quarry_mesh.top_radius = quarry_radius
	quarry_mesh.bottom_radius = quarry_radius + 2.5
	quarry_mesh.height = 1.0

	var quarry_mat = StandardMaterial3D.new()
	var quarry_tex_path = "res://assets/environment/terrain_rocky_mine.png"
	if ResourceLoader.exists(quarry_tex_path):
		var tex = load(quarry_tex_path)
		quarry_mat.albedo_texture = tex
		quarry_mat.uv1_scale = Vector3(6.0, 6.0, 1.0)
		quarry_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	else:
		quarry_mat.albedo_color = Color(0.40, 0.42, 0.45)
	quarry_mat.roughness = 0.75

	var quarry_node = MeshInstance3D.new()
	quarry_node.mesh = quarry_mesh
	quarry_node.material_override = quarry_mat
	quarry_node.position = quarry_center + Vector3(0.0, 0.9, 0.0)
	add_child(quarry_node)

	# 4. Scenic Ancient Monolith Bluff (North-West)
	var bluff_center = island1_center + Vector3(-24.0, 0.0, -22.0)
	var bluff_radius = 13.0
	var bluff_mesh = CylinderMesh.new()
	bluff_mesh.top_radius = bluff_radius
	bluff_mesh.bottom_radius = bluff_radius + 2.0
	bluff_mesh.height = 1.2

	var bluff_mat = StandardMaterial3D.new()
	bluff_mat.albedo_color = Color(0.35, 0.48, 0.32)
	bluff_mat.roughness = 0.8

	var bluff_node = MeshInstance3D.new()
	bluff_node.mesh = bluff_mesh
	bluff_node.material_override = bluff_mat
	bluff_node.position = bluff_center + Vector3(0.0, 1.0, 0.0)
	add_child(bluff_node)

func build_enemy_island() -> void:
	# Enemy Island Sand Base
	var sand_mesh = CylinderMesh.new()
	sand_mesh.top_radius = island2_radius
	sand_mesh.bottom_radius = island2_radius + 4.0
	sand_mesh.height = 1.0

	var sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.75, 0.68, 0.52)
	sand_mat.roughness = 0.9

	var sand_node = MeshInstance3D.new()
	sand_node.mesh = sand_mesh
	sand_node.material_override = sand_mat
	sand_node.position = island2_center + Vector3(0.0, 0.1, 0.0)
	add_child(sand_node)

	# Enemy Plateau
	var grass_mesh = CylinderMesh.new()
	grass_mesh.top_radius = island2_radius * 0.85
	grass_mesh.bottom_radius = island2_radius * 0.90
	grass_mesh.height = 0.6

	var grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.38, 0.45, 0.32)
	grass_mat.roughness = 0.85

	var grass_node = MeshInstance3D.new()
	grass_node.mesh = grass_mesh
	grass_node.material_override = grass_mat
	grass_node.position = island2_center + Vector3(0.0, 0.5, 0.0)
	add_child(grass_node)

func spawn_initial_resources() -> void:
	var res_container = Node3D.new()
	res_container.name = "ResourceNodes"
	add_child(res_container)

	# ==========================================
	# 1. THE FORESTS OF ISLAND EMPIRE
	# A. Whispering Pines (North & West Ridge)
	# ==========================================
	var forest_center = island1_center + Vector3(-22.0, 0.0, 14.0)
	var pine_offsets = [
		Vector3(-6.0, 0.8, -6.0),
		Vector3(-10.0, 0.8, -3.0),
		Vector3(-14.0, 0.8, -8.0),
		Vector3(-4.0, 0.8, -10.0),
		Vector3(-8.0, 0.8, 4.0),
		Vector3(-12.0, 0.8, 2.0),
		Vector3(-6.0, 0.8, 8.0),
		Vector3(-16.0, 0.8, 6.0),
		Vector3(-18.0, 0.8, -2.0),
		Vector3(-10.0, 0.8, 18.0),
		Vector3(-6.0, 0.8, 22.0),
		Vector3(-14.0, 0.8, -14.0)
	]
	for off in pine_offsets:
		spawn_resource(res_container, "wood", forest_center + off, 220, "pine")

	# B. Majestic Broadleaf Oaks (Central Clearings & Capital Glade)
	var oak_offsets = [
		Vector3(12.0, 0.8, 12.0),
		Vector3(16.0, 0.8, 8.0),
		Vector3(8.0, 0.8, 18.0),
		Vector3(14.0, 0.8, 20.0),
		Vector3(-12.0, 0.8, -18.0),
		Vector3(-6.0, 0.8, -22.0),
		Vector3(4.0, 0.8, -12.0),
		Vector3(8.0, 0.8, -8.0)
	]
	for off in oak_offsets:
		spawn_resource(res_container, "wood", island1_center + off, 250, "oak")

	# C. Tropical Coconut Palms (Sunny Perimeter Beaches)
	var palm_offsets = [
		Vector3(-36.0, 0.3, 0.0),
		Vector3(-34.0, 0.3, 16.0),
		Vector3(-28.0, 0.3, 26.0),
		Vector3(0.0, 0.3, 36.0),
		Vector3(18.0, 0.3, 32.0),
		Vector3(34.0, 0.3, 14.0),
		Vector3(36.0, 0.3, -4.0),
		Vector3(26.0, 0.3, 26.0)
	]
	for off in palm_offsets:
		spawn_resource(res_container, "wood", island1_center + off, 180, "palm")

	# Berry Bush Foraging Groves (along the forest border)
	var food_offsets = [
		Vector3(-12.0, 0.8, 8.0),
		Vector3(-8.0, 0.8, 10.0),
		Vector3(-14.0, 0.8, 12.0),
		Vector3(-10.0, 0.8, 14.0),
		Vector3(-4.0, 0.8, 12.0),
		Vector3(-6.0, 0.8, 16.0),
		Vector3(2.0, 0.8, 14.0),
		Vector3(6.0, 0.8, 12.0)
	]
	for off in food_offsets:
		spawn_resource(res_container, "food", island1_center + off, 160)

	# ==========================================
	# 2. MOUNTAIN QUARRY & GOLD BASIN (North-East)
	# 10 Stone Boulders & 6 Gold Veins
	# ==========================================
	var quarry_center = island1_center + Vector3(24.0, 0.0, -18.0)
	var stone_offsets = [
		Vector3(-6.0, 1.4, -4.0),
		Vector3(-3.0, 1.4, -8.0),
		Vector3(2.0, 1.4, -6.0),
		Vector3(6.0, 1.4, -3.0),
		Vector3(4.0, 1.4, 2.0),
		Vector3(-2.0, 1.4, 4.0),
		Vector3(-7.0, 1.4, 2.0),
		Vector3(8.0, 1.4, -7.0),
		Vector3(-5.0, 1.4, -10.0),
		Vector3(1.0, 1.4, 7.0)
	]
	for off in stone_offsets:
		spawn_resource(res_container, "stone", quarry_center + off, 320)

	var gold_offsets = [
		Vector3(-1.0, 1.4, -2.0),
		Vector3(3.0, 1.4, -1.0),
		Vector3(0.0, 1.4, 3.0),
		Vector3(5.0, 1.4, 5.0),
		Vector3(-4.0, 1.4, 6.0),
		Vector3(7.0, 1.4, 0.0)
	]
	for off in gold_offsets:
		spawn_resource(res_container, "gold", quarry_center + off, 380)

	# ==========================================
	# 3. ENEMY ISLAND RESOURCES
	# ==========================================
	var enemy_trees = [
		Vector3(-14.0, 0.8, -12.0),
		Vector3(-18.0, 0.8, 8.0),
		Vector3(10.0, 0.8, -14.0),
		Vector3(16.0, 0.8, 12.0),
		Vector3(-8.0, 0.8, -18.0),
		Vector3(12.0, 0.8, 16.0)
	]
	for off in enemy_trees:
		spawn_resource(res_container, "wood", island2_center + off, 200, "pine")

	var enemy_stones = [
		Vector3(18.0, 0.8, -8.0),
		Vector3(20.0, 0.8, 6.0),
		Vector3(-16.0, 0.8, 14.0)
	]
	for off in enemy_stones:
		spawn_resource(res_container, "stone", island2_center + off, 250)

func spawn_scenic_landmarks() -> void:
	# Spawn Ancient Monolith Landmark on North-West Scenic Bluff
	var monolith_path = "res://assets/models/scenic_monolith.glb"
	if ResourceLoader.exists(monolith_path):
		var m_res = load(monolith_path)
		if m_res:
			var m_inst = m_res.instantiate()
			var bluff_center = island1_center + Vector3(-24.0, 1.5, -22.0)
			m_inst.position = bluff_center
			add_child(m_inst)

func spawn_resource(parent: Node3D, type: String, pos: Vector3, amount: int, variant: String = "") -> void:
	var node = Node3D.new()
	node.set_script(preload("res://src/economy/resource_node.gd"))
	parent.add_child(node)
	node.call("setup", type, pos, amount, variant)

func is_on_player_island(pos: Vector3) -> bool:
	return pos.distance_to(island1_center) <= island1_radius

func is_on_enemy_island(pos: Vector3) -> bool:
	return pos.distance_to(island2_center) <= island2_radius

func is_on_any_island(pos: Vector3) -> bool:
	return is_on_player_island(pos) or is_on_enemy_island(pos)
