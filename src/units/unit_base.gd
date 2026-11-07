class_name UnitBase
extends CharacterBody3D

signal unit_died(unit: UnitBase)

enum State {
	IDLE,
	MOVING,
	GATHERING,
	DELIVERING,
	ATTACKING,
	EMBARKED
}

@export var unit_name: String = "Unit"
@export var team: String = "player" # "player" or "enemy"
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var move_speed: float = 6.0
@export var attack_damage: int = 10
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.2

var state: State = State.IDLE
var is_selected: bool = false
var target_destination: Vector3
var target_entity: Node3D
var attack_timer: float = 0.0

var selection_ring: MeshInstance3D
var visual_mesh: Node3D
var hp_bar_fill: MeshInstance3D

func _ready() -> void:
	current_hp = max_hp
	target_destination = global_position if is_inside_tree() else position
	build_visual()
	build_collision()
	build_selection_ring()
	build_overhead_hp()

func build_visual() -> void:
	visual_mesh = Node3D.new()
	visual_mesh.name = "Visual"
	add_child(visual_mesh)

	# Torso / Tunic
	var tunic_mesh = CylinderMesh.new()
	tunic_mesh.top_radius = 0.3
	tunic_mesh.bottom_radius = 0.36
	tunic_mesh.height = 0.8
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.2, 0.45, 0.85) if team == "player" else Color(0.85, 0.25, 0.2)
	var tunic_node = MeshInstance3D.new()
	tunic_node.mesh = tunic_mesh
	tunic_node.material_override = t_mat
	tunic_node.position = Vector3(0.0, 0.5, 0.0)
	visual_mesh.add_child(tunic_node)

	# Head with skin tone
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.26
	head_mesh.height = 0.52
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.96, 0.82, 0.72)
	var head_node = MeshInstance3D.new()
	head_node.mesh = head_mesh
	head_node.material_override = h_mat
	head_node.position = Vector3(0.0, 1.1, 0.0)
	visual_mesh.add_child(head_node)

func build_collision() -> void:
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.4
	col.shape = cap
	col.position = Vector3(0.0, 0.7, 0.0)
	add_child(col)
	set_meta("entity", self)

func build_selection_ring() -> void:
	selection_ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.7
	selection_ring.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.9, 0.2) if team == "player" else Color(1.0, 0.2, 0.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_ring.material_override = mat
	selection_ring.position = Vector3(0.0, 0.05, 0.0)
	selection_ring.visible = false
	add_child(selection_ring)

func build_overhead_hp() -> void:
	var hp_bg = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 0.12, 0.05)
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.2, 0.2, 0.2)
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hp_bg.mesh = box
	hp_bg.material_override = bg_mat
	hp_bg.position = Vector3(0.0, 1.8, 0.0)
	add_child(hp_bg)

	hp_bar_fill = MeshInstance3D.new()
	var fill_box = BoxMesh.new()
	fill_box.size = Vector3(0.96, 0.08, 0.06)
	var fill_mat = StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.2, 0.85, 0.2)
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hp_bar_fill.mesh = fill_box
	hp_bar_fill.material_override = fill_mat
	hp_bar_fill.position = Vector3(0.0, 1.8, 0.01)
	add_child(hp_bar_fill)

func update_hp_bar() -> void:
	if is_instance_valid(hp_bar_fill):
		var pct = clamp(float(current_hp) / float(max_hp), 0.0, 1.0)
		hp_bar_fill.scale.x = pct
		hp_bar_fill.position.x = -(1.0 - pct) * 0.48

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selection_ring:
		selection_ring.visible = selected

func command_move_to(pos: Vector3) -> void:
	target_entity = null
	target_destination = pos
	state = State.MOVING

func command_attack(entity: Node3D) -> void:
	target_entity = entity
	state = State.ATTACKING

func _physics_process(delta: float) -> void:
	attack_timer += delta

	match state:
		State.IDLE:
			velocity = Vector3.ZERO
		State.MOVING:
			move_towards_destination(delta)
		State.ATTACKING:
			handle_combat(delta)

	move_and_slide()

func move_towards_destination(delta: float) -> void:
	var dist = global_position.distance_to(target_destination)
	if dist <= 0.6:
		state = State.IDLE
		velocity = Vector3.ZERO
		return

	var dir = (target_destination - global_position).normalized()
	dir.y = 0.0
	velocity = dir * move_speed
	look_at_safe(global_position + dir)

func handle_combat(delta: float) -> void:
	if not is_instance_valid(target_entity):
		state = State.IDLE
		velocity = Vector3.ZERO
		return

	var dist = global_position.distance_to(target_entity.global_position)
	if dist > attack_range:
		# Approach
		var dir = (target_entity.global_position - global_position).normalized()
		dir.y = 0.0
		velocity = dir * move_speed
		look_at_safe(global_position + dir)
	else:
		# Attack
		velocity = Vector3.ZERO
		look_at_safe(target_entity.global_position)
		if attack_timer >= attack_cooldown:
			attack_timer = 0.0
			perform_attack()

func perform_attack() -> void:
	if is_instance_valid(target_entity) and target_entity.has_method("take_damage"):
		target_entity.take_damage(attack_damage)

func look_at_safe(target_pos: Vector3) -> void:
	var flat_target = Vector3(target_pos.x, global_position.y, target_pos.z)
	if global_position.distance_squared_to(flat_target) > 0.01:
		look_at(flat_target, Vector3.UP)

func take_damage(amount: int) -> void:
	current_hp -= amount
	update_hp_bar()
	if is_inside_tree() and get_parent():
		var ft = FloatingText.new()
		get_parent().add_child(ft)
		ft.setup(global_position + Vector3(0.0, 1.8, 0.0), "-" + str(amount), Color(1.0, 0.25, 0.2))
	if current_hp <= 0:
		current_hp = 0
		die()

func die() -> void:
	emit_signal("unit_died", self)
	if team == "player" and GameManager.instance:
		GameManager.instance.remove_population(1)
	queue_free()
