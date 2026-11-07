class_name TransportShip
extends CharacterBody3D

signal ship_destroyed(ship: TransportShip)

@export var max_capacity: int = 8
@export var move_speed: float = 7.5
@export var max_hp: int = 350
@export var current_hp: int = 350

var embarked_units: Array[UnitBase] = []
var is_selected: bool = false
var target_destination: Vector3
var selection_ring: MeshInstance3D

func _ready() -> void:
	current_hp = max_hp
	target_destination = global_position
	build_visual()
	build_collision()
	build_selection_ring()

func build_visual() -> void:
	# Wooden Hull
	var hull = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(2.5, 1.4, 5.5)
	var hull_mat = StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.42, 0.26, 0.16)
	hull.mesh = prism
	hull.material_override = hull_mat
	hull.position = Vector3(0.0, 0.4, 0.0)
	hull.rotation_degrees.x = 180.0
	add_child(hull)

	# Mast
	var mast = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.1
	cyl.height = 3.6
	var mast_mat = StandardMaterial3D.new()
	mast_mat.albedo_color = Color(0.35, 0.22, 0.12)
	mast.mesh = cyl
	mast.material_override = mast_mat
	mast.position = Vector3(0.0, 2.0, 0.2)
	add_child(mast)

	# White Sail
	var sail = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(2.4, 2.2)
	var sail_mat = StandardMaterial3D.new()
	sail_mat.albedo_color = Color(0.92, 0.9, 0.82)
	sail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sail.mesh = plane
	sail.material_override = sail_mat
	sail.position = Vector3(0.0, 2.4, 0.3)
	sail.rotation_degrees.x = 90.0
	add_child(sail)

func build_collision() -> void:
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.8, 2.0, 6.0)
	col.shape = box
	col.position = Vector3(0.0, 0.8, 0.0)
	add_child(col)
	set_meta("entity", self)

func build_selection_ring() -> void:
	selection_ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 2.8
	torus.outer_radius = 3.0
	selection_ring.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_ring.material_override = mat
	selection_ring.position = Vector3(0.0, 0.15, 0.0)
	selection_ring.visible = false
	add_child(selection_ring)

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selection_ring:
		selection_ring.visible = selected

func command_move_to(pos: Vector3) -> void:
	target_destination = pos

func embark_unit(unit: UnitBase) -> bool:
	if embarked_units.size() >= max_capacity:
		if GameManager.instance:
			GameManager.instance.post_notification("Transport is full! (Max 8 units)")
		return false

	embarked_units.append(unit)
	unit.visible = false
	unit.process_mode = Node.PROCESS_MODE_DISABLED
	unit.state = UnitBase.State.EMBARKED
	if GameManager.instance:
		GameManager.instance.post_notification("Unit embarked. (" + str(embarked_units.size()) + "/" + str(max_capacity) + ")")
	return true

func disembark_all(landing_pos: Vector3) -> void:
	if embarked_units.is_empty():
		return

	var angle_step = (PI * 2.0) / float(embarked_units.size())
	for i in range(embarked_units.size()):
		var u = embarked_units[i]
		if is_instance_valid(u):
			var offset = Vector3(cos(i * angle_step) * 2.5, 0.5, sin(i * angle_step) * 2.5)
			u.global_position = landing_pos + offset
			u.visible = true
			u.process_mode = Node.PROCESS_MODE_INHERIT
			u.state = UnitBase.State.IDLE
	embarked_units.clear()
	if GameManager.instance:
		GameManager.instance.post_notification("Troops disembarked on shore!")

func _physics_process(delta: float) -> void:
	var dist = global_position.distance_to(target_destination)
	if dist > 0.8:
		var dir = (target_destination - global_position).normalized()
		dir.y = 0.0
		velocity = dir * move_speed
		var flat_target = Vector3(target_destination.x, global_position.y, target_destination.z)
		look_at(flat_target, Vector3.UP)
	else:
		velocity = Vector3.ZERO

	# Gentle bobbing on water
	position.y = 0.15 + sin(Time.get_ticks_msec() * 0.002) * 0.08
	move_and_slide()

func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		for u in embarked_units:
			if is_instance_valid(u):
				u.queue_free()
		queue_free()
