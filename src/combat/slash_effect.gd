class_name SlashEffect
extends Node3D

var lifetime: float = 0.28
var elapsed: float = 0.0
var slash_color: Color = Color(1.0, 0.8, 0.3)
var slash_arc: MeshInstance3D
var sparks: Array[MeshInstance3D] = []
var spark_velocities: Array[Vector3] = []

func setup(pos: Vector3, dir: Vector3 = Vector3.FORWARD, color: Color = Color(1.0, 0.8, 0.3)) -> void:
	slash_color = color
	if is_inside_tree():
		global_position = pos
		if dir.length_squared() > 0.01:
			look_at_safe(global_position + dir)
	else:
		position = pos
	build_visual()

func look_at_safe(target_pos: Vector3) -> void:
	if not is_inside_tree():
		return
	var flat = Vector3(target_pos.x, global_position.y, target_pos.z)
	if global_position.distance_squared_to(flat) > 0.01:
		look_at(flat, Vector3.UP)

func build_visual() -> void:
	# 1. Crescent Slash Arc Blade
	slash_arc = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.65
	torus.outer_radius = 0.85
	var mat = StandardMaterial3D.new()
	mat.albedo_color = slash_color
	mat.emission_enabled = true
	mat.emission = slash_color
	mat.emission_energy_multiplier = 3.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	slash_arc.mesh = torus
	slash_arc.material_override = mat
	slash_arc.rotation_degrees.x = 75.0
	slash_arc.scale = Vector3(0.3, 0.3, 0.3)
	add_child(slash_arc)

	# 2. Bursting Spark Particles
	for i in range(4):
		var sp = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.08, 0.08, 0.08)
		var smat = StandardMaterial3D.new()
		smat.albedo_color = slash_color.lightened(0.3)
		smat.emission_enabled = true
		smat.emission = slash_color.lightened(0.3)
		smat.emission_energy_multiplier = 4.0
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sp.mesh = box
		sp.material_override = smat
		add_child(sp)
		sparks.append(sp)

		var v = Vector3(
			randf_range(-2.5, 2.5),
			randf_range(1.0, 3.5),
			randf_range(-2.5, 2.5)
		)
		spark_velocities.append(v)

func _process(delta: float) -> void:
	elapsed += delta
	var progress = clamp(elapsed / lifetime, 0.0, 1.0)

	# Expand and fade arc
	if slash_arc:
		var s = lerpf(0.5, 1.3, progress)
		slash_arc.scale = Vector3(s, s, s)
		var mat = slash_arc.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = 1.0 - progress

	# Move spark debris
	for i in range(sparks.size()):
		var sp = sparks[i]
		if is_instance_valid(sp):
			sp.position += spark_velocities[i] * delta
			spark_velocities[i].y -= 9.8 * delta # gravity
			var scale_pct = 1.0 - progress
			sp.scale = Vector3(scale_pct, scale_pct, scale_pct)

	if elapsed >= lifetime:
		queue_free()
