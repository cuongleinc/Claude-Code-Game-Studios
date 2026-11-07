class_name WarGalleon
extends CharacterBody3D

signal ship_destroyed(ship: WarGalleon)

@export var move_speed: float = 6.8
@export var max_hp: int = 550
@export var current_hp: int = 550
@export var cannon_range: float = 22.0
@export var cannon_cooldown: float = 2.4
@export var cannon_damage: int = 35

var team: String = "player"
var is_selected: bool = false
var target_destination: Vector3
var target_enemy: Node3D
var cannon_timer: float = 0.0
var selection_ring: MeshInstance3D

func _ready() -> void:
	current_hp = max_hp
	target_destination = global_position if is_inside_tree() else position
	build_visual()
	build_collision()
	build_selection_ring()

func build_visual() -> void:
	# Large Warship Hull
	var hull = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(3.4, 1.8, 7.5)
	var hull_mat = StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.32, 0.18, 0.1) # Dark oak
	hull.mesh = prism
	hull.material_override = hull_mat
	hull.position = Vector3(0.0, 0.5, 0.0)
	hull.rotation_degrees.x = 180.0
	add_child(hull)

	# Fore and Main Masts
	for z_pos in [-1.2, 1.5]:
		var mast = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.09
		cyl.bottom_radius = 0.12
		cyl.height = 4.2
		var mast_mat = StandardMaterial3D.new()
		mast_mat.albedo_color = Color(0.28, 0.16, 0.08)
		mast.mesh = cyl
		mast.material_override = mast_mat
		mast.position = Vector3(0.0, 2.3, z_pos)
		add_child(mast)

		# Sails with imperial crest color
		var sail = MeshInstance3D.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(2.6, 2.2)
		var sail_mat = StandardMaterial3D.new()
		sail_mat.albedo_color = Color(0.2, 0.45, 0.85) if team == "player" else Color(0.85, 0.2, 0.2)
		sail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		sail.mesh = plane
		sail.material_override = sail_mat
		sail.position = Vector3(0.0, 2.6, z_pos + 0.1)
		sail.rotation_degrees.x = 90.0
		add_child(sail)

	# Broadside Cannons (little black cylinders)
	for x_side in [-1.7, 1.7]:
		for z_off in [-1.8, 0.0, 1.8]:
			var cannon = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.08
			cyl.bottom_radius = 0.1
			cyl.height = 0.6
			var c_mat = StandardMaterial3D.new()
			c_mat.albedo_color = Color(0.12, 0.12, 0.14)
			c_mat.metallic = 0.9
			cannon.mesh = cyl
			cannon.material_override = c_mat
			cannon.position = Vector3(x_side, 0.6, z_off)
			cannon.rotation_degrees.z = 90.0 if x_side > 0 else -90.0
			add_child(cannon)

func build_collision() -> void:
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(3.8, 2.5, 8.0)
	col.shape = box
	col.position = Vector3(0.0, 1.0, 0.0)
	add_child(col)
	set_meta("entity", self)

func build_selection_ring() -> void:
	selection_ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 3.6
	torus.outer_radius = 3.85
	selection_ring.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_ring.material_override = mat
	selection_ring.position = Vector3(0.0, 0.2, 0.0)
	selection_ring.visible = false
	add_child(selection_ring)

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selection_ring:
		selection_ring.visible = selected

func command_move_to(pos: Vector3) -> void:
	target_destination = pos
	target_enemy = null

func command_attack(entity: Node3D) -> void:
	target_enemy = entity

func _physics_process(delta: float) -> void:
	cannon_timer += delta

	# Naval Navigation
	var dist = global_position.distance_to(target_destination)
	if dist > 1.0:
		var dir = (target_destination - global_position).normalized()
		dir.y = 0.0
		velocity = dir * move_speed
		var flat_target = Vector3(target_destination.x, global_position.y, target_destination.z)
		look_at(flat_target, Vector3.UP)
	else:
		velocity = Vector3.ZERO

	# Water bobbing
	position.y = 0.2 + sin(Time.get_ticks_msec() * 0.0025) * 0.1
	move_and_slide()

	# Broadside Artillery Auto-targeting
	if cannon_timer >= cannon_cooldown:
		check_and_fire_cannons()

func check_and_fire_cannons() -> void:
	var enemy_group = "enemy_units" if team == "player" else "player_units"
	var targets = get_tree().get_nodes_in_group(enemy_group)
	var chosen: Node3D = target_enemy

	if not is_instance_valid(chosen):
		for t in targets:
			if is_instance_valid(t) and global_position.distance_to(t.global_position) <= cannon_range:
				chosen = t
				break

	if is_instance_valid(chosen):
		cannon_timer = 0.0
		fire_cannon_shot(chosen)

func fire_cannon_shot(t: Node3D) -> void:
	var proj = Projectile.new()
	get_parent().add_child(proj)
	proj.setup(global_position + Vector3(0.0, 1.5, 0.0), t, cannon_damage, true)
	if GameManager.instance:
		GameManager.instance.post_notification("War Galleon fired broadside cannons!")

func take_damage(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		emit_signal("ship_destroyed", self)
		queue_free()
