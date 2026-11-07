class_name Projectile
extends Node3D

var target: Node3D
var speed: float = 22.0
var damage: int = 15
var start_pos: Vector3
var target_pos: Vector3
var progress: float = 0.0
var total_dist: float = 1.0
var is_boulder: bool = false

func setup(p_start: Vector3, p_target: Node3D, p_damage: int, p_is_boulder: bool = false) -> void:
	start_pos = p_start
	target = p_target
	damage = p_damage
	is_boulder = p_is_boulder
	
	if is_inside_tree():
		global_position = p_start
	else:
		position = p_start

	if is_instance_valid(target):
		target_pos = target.global_position + Vector3(0.0, 0.8, 0.0)
	else:
		target_pos = p_start + Vector3(0.0, 0.0, 5.0)

	total_dist = max(1.0, start_pos.distance_to(target_pos))
	build_visual()

func build_visual() -> void:
	if is_boulder:
		var ball = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.35
		sphere.height = 0.7
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.25, 0.28) # Cannon iron / stone
		mat.metallic = 0.4
		mat.roughness = 0.8
		ball.mesh = sphere
		ball.material_override = mat
		add_child(ball)
	else:
		var shaft = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.04
		cyl.bottom_radius = 0.04
		cyl.height = 0.7
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.8, 0.5)
		shaft.mesh = cyl
		shaft.material_override = mat
		shaft.rotation_degrees.x = 90.0
		add_child(shaft)

func _process(delta: float) -> void:
	if is_instance_valid(target):
		target_pos = target.global_position + Vector3(0.0, 0.8, 0.0)

	var move_step = (speed * delta) / total_dist
	progress += move_step

	if progress >= 1.0:
		if is_instance_valid(target) and target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
		return

	# Parabolic arc
	var current_ground = start_pos.lerp(target_pos, progress)
	var arc_height = sin(progress * PI) * (total_dist * (0.28 if is_boulder else 0.18))
	global_position = current_ground + Vector3(0.0, arc_height, 0.0)
	if not is_boulder:
		look_at(target_pos, Vector3.UP)
