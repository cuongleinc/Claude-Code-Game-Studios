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
var tunic_node: MeshInstance3D
var tunic_mat: StandardMaterial3D
var weapon_node: Node3D
var hp_bar_fill: MeshInstance3D

# Procedural Animation State
var walk_cycle: float = 0.0
var idle_cycle: float = 0.0
var is_attacking_anim: bool = false
var attack_anim_time: float = 0.0
var hurt_timer: float = 0.0
var is_dying: bool = false
var death_timer: float = 0.0
var aggro_timer: float = 0.0

func _ready() -> void:
	current_hp = max_hp
	target_destination = global_position if is_inside_tree() else position
	if team == "player":
		add_to_group("player_units")
	else:
		add_to_group("enemy_units")
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
	tunic_mat = StandardMaterial3D.new()
	tunic_mat.albedo_color = Color(0.2, 0.45, 0.85) if team == "player" else Color(0.85, 0.25, 0.2)
	tunic_node = MeshInstance3D.new()
	tunic_node.mesh = tunic_mesh
	tunic_node.material_override = tunic_mat
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
	col.name = "CollisionShape3D"
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

func trigger_attack_anim() -> void:
	is_attacking_anim = true
	attack_anim_time = 0.0

func _physics_process(delta: float) -> void:
	# Death Animation Process
	if is_dying:
		death_timer += delta
		if visual_mesh:
			visual_mesh.rotation.x = lerpf(visual_mesh.rotation.x, -PI * 0.48, delta * 7.0)
			visual_mesh.position.y = lerpf(visual_mesh.position.y, 0.12, delta * 5.0)
			visual_mesh.position.z = lerpf(visual_mesh.position.z, -0.3, delta * 4.0)
			if death_timer >= 1.5:
				var fade = clamp(1.0 - ((death_timer - 1.5) / 1.0), 0.0, 1.0)
				visual_mesh.scale = Vector3(fade, fade, fade)
		if death_timer >= 2.5:
			queue_free()
		return

	attack_timer += delta
	_process_animations(delta)

	# Autonomous Guard & Aggro Scan
	if (state == State.IDLE or (state == State.MOVING and not is_instance_valid(target_entity))):
		if team == "enemy" or (self is MilitaryUnit):
			aggro_timer += delta
			if aggro_timer >= 0.4:
				aggro_timer = randf_range(0.0, 0.15)
				scan_for_hostiles()

	match state:
		State.IDLE:
			velocity = Vector3.ZERO
		State.MOVING:
			move_towards_destination(delta)
		State.ATTACKING:
			handle_combat(delta)

	move_and_slide()

func scan_for_hostiles() -> void:
	if not is_inside_tree() or is_dying:
		return
	var hostile_group = "enemy_units" if team == "player" else "player_units"
	var hostiles = get_tree().get_nodes_in_group(hostile_group)
	var detection_range = 14.0 if ("military_type" in self and self.military_type == "archer") else 10.0

	var nearest_target: Node3D = null
	var min_dist = detection_range

	for target in hostiles:
		if is_instance_valid(target) and target is UnitBase and not target.is_dying:
			var d = global_position.distance_to(target.global_position)
			if d < min_dist:
				min_dist = d
				nearest_target = target

	if not nearest_target and team == "enemy":
		var p_buildings = get_tree().get_nodes_in_group("player_buildings")
		for b in p_buildings:
			if is_instance_valid(b) and b is BuildingBase:
				var d = global_position.distance_to(b.global_position)
				if d < min_dist:
					min_dist = d
					nearest_target = b

	if nearest_target:
		command_attack(nearest_target)

func _process_animations(delta: float) -> void:
	if not visual_mesh:
		return

	# 1. Hit Flash Recovery
	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0 and tunic_node and tunic_mat:
			tunic_node.material_override = tunic_mat

	# 2. Attack Lunge Animation
	if is_attacking_anim:
		attack_anim_time += delta
		var anim_len = 0.32
		var p = clamp(attack_anim_time / anim_len, 0.0, 1.0)
		if p < 0.35:
			# Windup
			var w_pct = p / 0.35
			visual_mesh.position.z = w_pct * 0.22
			visual_mesh.rotation.x = -w_pct * 0.15
			if weapon_node:
				weapon_node.rotation.x = deg_to_rad(25.0) - w_pct * 0.4
		elif p < 0.7:
			# Rapid forward strike
			var s_pct = (p - 0.35) / 0.35
			visual_mesh.position.z = 0.22 - s_pct * 0.65
			visual_mesh.rotation.x = -0.15 + s_pct * 0.35
			if weapon_node:
				weapon_node.rotation.x = deg_to_rad(25.0) + s_pct * 0.6
		else:
			# Recovery
			var r_pct = (p - 0.7) / 0.3
			visual_mesh.position.z = -0.43 + r_pct * 0.43
			visual_mesh.rotation.x = 0.20 - r_pct * 0.20
			if weapon_node:
				weapon_node.rotation.x = lerpf(weapon_node.rotation.x, deg_to_rad(25.0), delta * 12.0)

		if attack_anim_time >= anim_len:
			is_attacking_anim = false
			visual_mesh.position.z = 0.0
			visual_mesh.rotation.x = 0.0
		return

	# 3. Locomotion / Walk Cycle (Springy Bobbing & Lean)
	if velocity.length_squared() > 0.1:
		walk_cycle += delta * move_speed * 2.4
		visual_mesh.position.y = abs(sin(walk_cycle)) * 0.14
		visual_mesh.rotation.z = -sin(walk_cycle) * 0.08
		visual_mesh.rotation.x = 0.12
		if weapon_node:
			weapon_node.rotation.x = deg_to_rad(25.0) + sin(walk_cycle) * 0.25
	else:
		# 4. Idle Breathing
		idle_cycle += delta
		visual_mesh.position.y = sin(idle_cycle * 2.4) * 0.03
		visual_mesh.position.z = lerpf(visual_mesh.position.z, 0.0, delta * 10.0)
		visual_mesh.rotation.x = lerpf(visual_mesh.rotation.x, 0.0, delta * 10.0)
		visual_mesh.rotation.z = lerpf(visual_mesh.rotation.z, 0.0, delta * 10.0)
		if weapon_node:
			weapon_node.rotation.x = lerpf(weapon_node.rotation.x, deg_to_rad(25.0), delta * 8.0)

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
		# Approach target
		var dir = (target_entity.global_position - global_position).normalized()
		dir.y = 0.0
		velocity = dir * move_speed
		look_at_safe(global_position + dir)
	else:
		# In attack range: face target and strike
		velocity = Vector3.ZERO
		look_at_safe(target_entity.global_position)
		if attack_timer >= attack_cooldown:
			attack_timer = 0.0
			perform_attack()

func perform_attack() -> void:
	trigger_attack_anim()
	if is_instance_valid(target_entity) and target_entity.has_method("take_damage"):
		target_entity.take_damage(attack_damage, self)

func look_at_safe(target_pos: Vector3) -> void:
	var flat_target = Vector3(target_pos.x, global_position.y, target_pos.z)
	if global_position.distance_squared_to(flat_target) > 0.01:
		look_at(flat_target, Vector3.UP)

func take_damage(amount: int, attacker: Node3D = null) -> void:
	current_hp -= amount
	update_hp_bar()

	# Hurt flash & stagger
	hurt_timer = 0.14
	if tunic_node:
		var flash_mat = StandardMaterial3D.new()
		flash_mat.albedo_color = Color(1.0, 0.9, 0.9)
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tunic_node.material_override = flash_mat

	# Knockback recoil from attacker
	if is_instance_valid(attacker) and is_inside_tree() and attacker.is_inside_tree():
		var push_dir = (global_position - attacker.global_position).normalized()
		push_dir.y = 0.0
		velocity += push_dir * 3.5

	# Floating damage number
	if is_inside_tree() and get_parent():
		var ft = FloatingText.new()
		get_parent().add_child(ft)
		var text_col = Color(1.0, 0.25, 0.2)
		if amount >= 30:
			text_col = Color(1.0, 0.85, 0.1) # Critical strike
		ft.setup(global_position + Vector3(0.0, 1.8, 0.0), "-" + str(amount), text_col)

	# Auto-retaliate & alert nearby allies
	if (state == State.IDLE or state == State.MOVING) and is_instance_valid(attacker):
		command_attack(attacker)
		alert_nearby_allies(attacker)

	if current_hp <= 0:
		current_hp = 0
		die()

func alert_nearby_allies(enemy_target: Node3D) -> void:
	if not is_inside_tree():
		return
	var my_group = "player_units" if team == "player" else "enemy_units"
	var allies = get_tree().get_nodes_in_group(my_group)
	for ally in allies:
		if is_instance_valid(ally) and ally is UnitBase and ally != self:
			if ally.state == State.IDLE and ally.global_position.distance_to(global_position) <= 14.0:
				ally.command_attack(enemy_target)

func die() -> void:
	if is_dying:
		return
	is_dying = true
	state = State.IDLE
	velocity = Vector3.ZERO
	set_selected(false)

	if is_in_group("player_units"):
		remove_from_group("player_units")
	if is_in_group("enemy_units"):
		remove_from_group("enemy_units")

	# Disable collision shape
	var col = get_node_or_null("CollisionShape3D")
	if col is CollisionShape3D:
		col.set_deferred("disabled", true)

	emit_signal("unit_died", self)
	if team == "player" and GameManager.instance:
		GameManager.instance.remove_population(1)

	# Hide overhead UI
	if is_instance_valid(hp_bar_fill) and hp_bar_fill.get_parent():
		hp_bar_fill.get_parent().visible = false

	# For headless test runners or standalone runs, queue_free directly
	if not is_inside_tree() or Engine.is_editor_hint():
		queue_free()
