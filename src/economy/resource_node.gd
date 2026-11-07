class_name ResourceNode
extends Node3D

@export var resource_type: String = "wood"
@export var amount_remaining: int = 150
@export var max_amount: int = 150

var is_selected: bool = false
var selection_ring: MeshInstance3D

func setup(type: String, pos: Vector3, amount: int) -> void:
	resource_type = type
	amount_remaining = amount
	max_amount = amount
	if is_inside_tree():
		global_position = pos
	else:
		position = pos
	build_visual()

	build_collision()
	build_selection_ring()

func build_visual() -> void:
	match resource_type:
		"wood":
			# Tree trunk
			var trunk = MeshInstance3D.new()
			var trunk_mesh = CylinderMesh.new()
			trunk_mesh.top_radius = 0.2
			trunk_mesh.bottom_radius = 0.3
			trunk_mesh.height = 1.6
			var trunk_mat = StandardMaterial3D.new()
			trunk_mat.albedo_color = Color(0.45, 0.28, 0.15)
			trunk.mesh = trunk_mesh
			trunk.material_override = trunk_mat
			trunk.position = Vector3(0.0, 0.8, 0.0)
			add_child(trunk)

			# Foliage cone
			var foliage = MeshInstance3D.new()
			var cone_mesh = CylinderMesh.new()
			cone_mesh.top_radius = 0.0
			cone_mesh.bottom_radius = 1.4
			cone_mesh.height = 2.4
			var foliage_mat = StandardMaterial3D.new()
			foliage_mat.albedo_color = Color(0.18, 0.52, 0.22)
			foliage.mesh = cone_mesh
			foliage.material_override = foliage_mat
			foliage.position = Vector3(0.0, 2.2, 0.0)
			add_child(foliage)

		"stone":
			var boulder = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.9
			sphere.height = 1.3
			var stone_mat = StandardMaterial3D.new()
			stone_mat.albedo_color = Color(0.55, 0.55, 0.58)
			stone_mat.roughness = 0.8
			boulder.mesh = sphere
			boulder.material_override = stone_mat
			boulder.position = Vector3(0.0, 0.5, 0.0)
			add_child(boulder)

		"food":
			var bush = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.75
			sphere.height = 1.0
			var bush_mat = StandardMaterial3D.new()
			bush_mat.albedo_color = Color(0.25, 0.62, 0.25)
			bush.mesh = sphere
			bush.material_override = bush_mat
			bush.position = Vector3(0.0, 0.4, 0.0)
			add_child(bush)

			# Red berry dots
			for i in range(4):
				var berry = MeshInstance3D.new()
				var b_mesh = SphereMesh.new()
				b_mesh.radius = 0.12
				b_mesh.height = 0.24
				var b_mat = StandardMaterial3D.new()
				b_mat.albedo_color = Color(0.9, 0.15, 0.15)
				berry.mesh = b_mesh
				berry.material_override = b_mat
				var angle = i * PI * 0.5
				berry.position = Vector3(cos(angle) * 0.5, 0.5 + sin(angle) * 0.2, sin(angle) * 0.5)
				add_child(berry)

		"gold":
			var ore = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(1.2, 1.0, 1.2)
			var gold_mat = StandardMaterial3D.new()
			gold_mat.albedo_color = Color(0.95, 0.75, 0.12)
			gold_mat.metallic = 0.8
			gold_mat.roughness = 0.3
			ore.mesh = box
			ore.material_override = gold_mat
			ore.position = Vector3(0.0, 0.5, 0.0)
			ore.rotation_degrees = Vector3(15.0, 30.0, 10.0)
			add_child(ore)

func build_collision() -> void:
	var body = StaticBody3D.new()
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1.8, 2.5, 1.8)
	col.shape = box_shape
	col.position = Vector3(0.0, 1.0, 0.0)
	body.add_child(col)
	body.set_meta("entity", self)
	add_child(body)

func build_selection_ring() -> void:
	selection_ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.2
	torus.outer_radius = 1.35
	selection_ring.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_ring.material_override = mat
	selection_ring.position = Vector3(0.0, 0.1, 0.0)
	selection_ring.visible = false
	add_child(selection_ring)

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selection_ring:
		selection_ring.visible = selected

func harvest(amount: int) -> int:
	var harvested = min(amount, amount_remaining)
	amount_remaining -= harvested
	scale = Vector3.ONE * max(0.3, float(amount_remaining) / float(max_amount))
	if amount_remaining <= 0:
		queue_free()
	return harvested
