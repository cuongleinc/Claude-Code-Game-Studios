class_name Catapult
extends MilitaryUnit

func _ready() -> void:
	military_type = "catapult"
	unit_name = "Catapult"
	max_hp = 220
	attack_damage = 45
	attack_range = 24.0
	attack_cooldown = 3.5
	move_speed = 3.4

	super._ready()
	build_catapult_visual()

func build_catapult_visual() -> void:
	# Hide humanoid visual if any
	for child in visual_mesh.get_children():
		child.queue_free()

	# Chassis frame
	var chassis = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.6, 0.35, 2.4)
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.4, 0.25, 0.15)
	chassis.mesh = box
	chassis.material_override = wood_mat
	chassis.position = Vector3(0.0, 0.45, 0.0)
	visual_mesh.add_child(chassis)

	# 4 Wheels
	var wheel_mat = StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.25, 0.15, 0.08)
	var wheel_positions = [
		Vector3(-0.9, 0.4, -0.7),
		Vector3(0.9, 0.4, -0.7),
		Vector3(-0.9, 0.4, 0.7),
		Vector3(0.9, 0.4, 0.7)
	]
	for wpos in wheel_positions:
		var wheel = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.35
		cyl.height = 0.18
		wheel.mesh = cyl
		wheel.material_override = wheel_mat
		wheel.position = wpos
		wheel.rotation_degrees.z = 90.0
		visual_mesh.add_child(wheel)

	# Upright A-frame
	var frame = MeshInstance3D.new()
	var fbox = BoxMesh.new()
	fbox.size = Vector3(1.2, 1.2, 0.25)
	frame.mesh = fbox
	frame.material_override = wood_mat
	frame.position = Vector3(0.0, 1.1, 0.1)
	visual_mesh.add_child(frame)

	# Throwing arm
	var arm = MeshInstance3D.new()
	var abox = BoxMesh.new()
	abox.size = Vector3(0.2, 2.0, 0.2)
	arm.mesh = abox
	arm.material_override = wood_mat
	arm.position = Vector3(0.0, 1.4, -0.2)
	arm.rotation_degrees.x = -35.0
	visual_mesh.add_child(arm)

	# Boulder in bucket
	var stone = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.5, 0.5, 0.52)
	stone.mesh = sphere
	stone.material_override = stone_mat
	stone.position = Vector3(0.0, 2.2, -0.8)
	visual_mesh.add_child(stone)

func perform_attack() -> void:
	if not is_instance_valid(target_entity):
		return

	var proj = Projectile.new()
	get_parent().add_child(proj)
	proj.setup(global_position + Vector3(0.0, 1.8, 0.0), target_entity, attack_damage, true)
	if GameManager.instance:
		GameManager.instance.post_notification("Catapult launched heavy siege boulder!")
