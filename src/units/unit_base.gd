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

# 3D LEGO Minifigure Rig Hierarchy
var minifig_root: Node3D
var hips_node: MeshInstance3D
var left_leg_pivot: Node3D
var left_leg_mesh: MeshInstance3D
var right_leg_pivot: Node3D
var right_leg_mesh: MeshInstance3D
var torso_node: MeshInstance3D
var neck_node: MeshInstance3D
var head_node: Node3D
var head_cylinder: MeshInstance3D
var head_stud: MeshInstance3D
var left_arm_pivot: Node3D
var left_arm_node: MeshInstance3D
var left_hand_node: MeshInstance3D
var right_arm_pivot: Node3D
var right_arm_node: MeshInstance3D
var right_hand_node: MeshInstance3D

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

	minifig_root = Node3D.new()
	minifig_root.name = "MinifigureRig"
	visual_mesh.add_child(minifig_root)

	# --- Materials: Authentic Glossy LEGO ABS Plastic ---
	var yellow_mat = StandardMaterial3D.new()
	yellow_mat.albedo_color = Color(1.0, 0.83, 0.08) # Iconic Minifig Yellow
	yellow_mat.roughness = 0.22

	tunic_mat = StandardMaterial3D.new()
	tunic_mat.albedo_color = Color(0.18, 0.46, 0.88) if team == "player" else Color(0.86, 0.22, 0.18)
	tunic_mat.roughness = 0.20

	var hips_mat = StandardMaterial3D.new()
	hips_mat.albedo_color = Color(0.22, 0.24, 0.26)
	hips_mat.roughness = 0.35

	var trousers_mat = StandardMaterial3D.new()
	trousers_mat.albedo_color = Color(0.12, 0.22, 0.44) if team == "player" else Color(0.35, 0.14, 0.14)
	trousers_mat.roughness = 0.30

	var black_gloss_mat = StandardMaterial3D.new()
	black_gloss_mat.albedo_color = Color(0.06, 0.06, 0.06)
	black_gloss_mat.roughness = 0.15

	# 1. Pelvis / Hips Block
	hips_node = MeshInstance3D.new()
	var hips_box = BoxMesh.new()
	hips_box.size = Vector3(0.34, 0.11, 0.19)
	hips_node.mesh = hips_box
	hips_node.material_override = hips_mat
	hips_node.position = Vector3(0.0, 0.38, 0.0)
	minifig_root.add_child(hips_node)

	# 2. Left Leg (Pivot at Hip Socket)
	left_leg_pivot = Node3D.new()
	left_leg_pivot.name = "LeftLegPivot"
	left_leg_pivot.position = Vector3(-0.088, 0.36, 0.0)
	minifig_root.add_child(left_leg_pivot)

	left_leg_mesh = MeshInstance3D.new()
	var leg_box = BoxMesh.new()
	leg_box.size = Vector3(0.145, 0.34, 0.17)
	left_leg_mesh.mesh = leg_box
	left_leg_mesh.material_override = trousers_mat
	left_leg_mesh.position = Vector3(0.0, -0.17, 0.0)
	left_leg_pivot.add_child(left_leg_mesh)

	var left_toe = MeshInstance3D.new()
	var toe_box = BoxMesh.new()
	toe_box.size = Vector3(0.145, 0.08, 0.08)
	left_toe.mesh = toe_box
	left_toe.material_override = trousers_mat
	left_toe.position = Vector3(0.0, -0.30, 0.07)
	left_leg_pivot.add_child(left_toe)

	# 3. Right Leg (Pivot at Hip Socket)
	right_leg_pivot = Node3D.new()
	right_leg_pivot.name = "RightLegPivot"
	right_leg_pivot.position = Vector3(0.088, 0.36, 0.0)
	minifig_root.add_child(right_leg_pivot)

	right_leg_mesh = MeshInstance3D.new()
	right_leg_mesh.mesh = leg_box
	right_leg_mesh.material_override = trousers_mat
	right_leg_mesh.position = Vector3(0.0, -0.17, 0.0)
	right_leg_pivot.add_child(right_leg_mesh)

	var right_toe = MeshInstance3D.new()
	right_toe.mesh = toe_box
	right_toe.material_override = trousers_mat
	right_toe.position = Vector3(0.0, -0.30, 0.07)
	right_leg_pivot.add_child(right_toe)

	# 4. Torso (Trapezoidal Minifigure Chest)
	torso_node = MeshInstance3D.new()
	torso_node.name = "Torso"
	var chest_box = BoxMesh.new()
	chest_box.size = Vector3(0.36, 0.40, 0.21)
	torso_node.mesh = chest_box
	torso_node.material_override = tunic_mat
	torso_node.position = Vector3(0.0, 0.63, 0.0)
	minifig_root.add_child(torso_node)
	tunic_node = torso_node # Preserves hit-flash & test compatibility

	# Shoulder Studs (2 Micro-Studs on top of shoulders)
	for sx in [-0.14, 0.14]:
		var s_stud = MeshInstance3D.new()
		var stud_cyl = CylinderMesh.new()
		stud_cyl.top_radius = 0.038
		stud_cyl.bottom_radius = 0.038
		stud_cyl.height = 0.035
		s_stud.mesh = stud_cyl
		s_stud.material_override = tunic_mat
		s_stud.position = Vector3(sx, 0.21, 0.0)
		torso_node.add_child(s_stud)

	# 5. Neck Ring
	neck_node = MeshInstance3D.new()
	var neck_cyl = CylinderMesh.new()
	neck_cyl.top_radius = 0.075
	neck_cyl.bottom_radius = 0.075
	neck_cyl.height = 0.05
	neck_node.mesh = neck_cyl
	neck_node.material_override = yellow_mat
	neck_node.position = Vector3(0.0, 0.855, 0.0)
	minifig_root.add_child(neck_node)

	# 6. Cylindrical Head with Top Stud & Cheerful Painted Face
	head_node = Node3D.new()
	head_node.name = "HeadNode"
	head_node.position = Vector3(0.0, 0.99, 0.0)
	minifig_root.add_child(head_node)

	head_cylinder = MeshInstance3D.new()
	var head_cyl = CylinderMesh.new()
	head_cyl.top_radius = 0.125
	head_cyl.bottom_radius = 0.125
	head_cyl.height = 0.22
	head_cylinder.mesh = head_cyl
	head_cylinder.material_override = yellow_mat
	head_node.add_child(head_cylinder)

	head_stud = MeshInstance3D.new()
	var hstud_cyl = CylinderMesh.new()
	hstud_cyl.top_radius = 0.062
	hstud_cyl.bottom_radius = 0.062
	hstud_cyl.height = 0.055
	head_stud.mesh = hstud_cyl
	head_stud.material_override = yellow_mat
	head_stud.position = Vector3(0.0, 0.135, 0.0)
	head_node.add_child(head_stud)

	# Expressive Painted Minifig Eyes
	for ex in [-0.046, 0.046]:
		var eye = MeshInstance3D.new()
		var eye_mesh = SphereMesh.new()
		eye_mesh.radius = 0.016
		eye_mesh.height = 0.032
		eye.mesh = eye_mesh
		eye.material_override = black_gloss_mat
		eye.position = Vector3(ex, 0.025, 0.122)
		head_node.add_child(eye)

	# Cheerful Classic Smile
	var smile = MeshInstance3D.new()
	var smile_box = BoxMesh.new()
	smile_box.size = Vector3(0.055, 0.012, 0.015)
	smile.mesh = smile_box
	smile.material_override = black_gloss_mat
	smile.position = Vector3(0.0, -0.04, 0.122)
	head_node.add_child(smile)

	# 7. Left Arm & Articulated C-Clamp Hand
	left_arm_pivot = Node3D.new()
	left_arm_pivot.name = "LeftArmPivot"
	left_arm_pivot.position = Vector3(-0.21, 0.76, 0.0)
	minifig_root.add_child(left_arm_pivot)

	left_arm_node = MeshInstance3D.new()
	var arm_box = BoxMesh.new()
	arm_box.size = Vector3(0.09, 0.28, 0.10)
	left_arm_node.mesh = arm_box
	left_arm_node.material_override = tunic_mat
	left_arm_node.position = Vector3(-0.02, -0.12, 0.02)
	left_arm_node.rotation_degrees.z = 10.0
	left_arm_pivot.add_child(left_arm_node)

	left_hand_node = MeshInstance3D.new()
	var hand_tube = TorusMesh.new()
	hand_tube.inner_radius = 0.022
	hand_tube.outer_radius = 0.052
	left_hand_node.mesh = hand_tube
	left_hand_node.material_override = yellow_mat
	left_hand_node.position = Vector3(-0.03, -0.27, 0.04)
	left_hand_node.rotation_degrees = Vector3(90.0, 0.0, 15.0)
	left_arm_pivot.add_child(left_hand_node)

	# 8. Right Arm & Articulated C-Clamp Hand (Weapon Grip)
	right_arm_pivot = Node3D.new()
	right_arm_pivot.name = "RightArmPivot"
	right_arm_pivot.position = Vector3(0.21, 0.76, 0.0)
	minifig_root.add_child(right_arm_pivot)

	right_arm_node = MeshInstance3D.new()
	right_arm_node.mesh = arm_box
	right_arm_node.material_override = tunic_mat
	right_arm_node.position = Vector3(0.02, -0.12, 0.02)
	right_arm_node.rotation_degrees.z = -10.0
	right_arm_pivot.add_child(right_arm_node)

	right_hand_node = MeshInstance3D.new()
	right_hand_node.mesh = hand_tube
	right_hand_node.material_override = yellow_mat
	right_hand_node.position = Vector3(0.03, -0.27, 0.04)
	right_hand_node.rotation_degrees = Vector3(90.0, 0.0, -15.0)
	right_arm_pivot.add_child(right_hand_node)

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

	# 2. Attack Strike Animation
	if is_attacking_anim:
		attack_anim_time += delta
		var anim_len = 0.32
		var p = clamp(attack_anim_time / anim_len, 0.0, 1.0)
		if p < 0.35:
			# Windup: Minifig pulls arm back
			var w_pct = p / 0.35
			visual_mesh.position.z = w_pct * 0.16
			visual_mesh.rotation.x = -w_pct * 0.12
			if right_arm_pivot:
				right_arm_pivot.rotation.x = -w_pct * deg_to_rad(75.0)
			if weapon_node:
				weapon_node.rotation.x = deg_to_rad(25.0) - w_pct * 0.4
		elif p < 0.7:
			# Rapid forward strike: Minifig chops arm forward
			var s_pct = (p - 0.35) / 0.35
			visual_mesh.position.z = 0.16 - s_pct * 0.42
			visual_mesh.rotation.x = -0.12 + s_pct * 0.26
			if right_arm_pivot:
				right_arm_pivot.rotation.x = -deg_to_rad(75.0) + s_pct * deg_to_rad(150.0)
			if weapon_node:
				weapon_node.rotation.x = deg_to_rad(25.0) + s_pct * 0.6
		else:
			# Recovery: return to rest
			var r_pct = (p - 0.7) / 0.3
			visual_mesh.position.z = -0.26 + r_pct * 0.26
			visual_mesh.rotation.x = 0.14 - r_pct * 0.14
			if right_arm_pivot:
				right_arm_pivot.rotation.x = lerpf(right_arm_pivot.rotation.x, 0.0, delta * 12.0)
			if weapon_node:
				weapon_node.rotation.x = lerpf(weapon_node.rotation.x, deg_to_rad(25.0), delta * 12.0)

		if attack_anim_time >= anim_len:
			is_attacking_anim = false
			visual_mesh.position.z = 0.0
			visual_mesh.rotation.x = 0.0
		return

	# 3. Locomotion / Minifigure Walk Cycle (Leg & Arm Joint Swinging)
	if velocity.length_squared() > 0.1:
		walk_cycle += delta * move_speed * 2.8
		var leg_swing = sin(walk_cycle) * 0.65
		if left_leg_pivot:
			left_leg_pivot.rotation.x = leg_swing
		if right_leg_pivot:
			right_leg_pivot.rotation.x = -leg_swing
		if left_arm_pivot:
			left_arm_pivot.rotation.x = -leg_swing * 0.8
		if right_arm_pivot and not is_attacking_anim:
			right_arm_pivot.rotation.x = leg_swing * 0.8

		# Characteristic springy Minifigure step bob
		visual_mesh.position.y = abs(sin(walk_cycle * 2.0)) * 0.06
		visual_mesh.rotation.z = -sin(walk_cycle) * 0.04
		visual_mesh.rotation.x = 0.08
		if weapon_node:
			weapon_node.rotation.x = deg_to_rad(25.0) + sin(walk_cycle) * 0.25
	else:
		# 4. Idle Breathing & Gentle Arm Rest
		idle_cycle += delta
		if left_leg_pivot:
			left_leg_pivot.rotation.x = lerpf(left_leg_pivot.rotation.x, 0.0, delta * 10.0)
		if right_leg_pivot:
			right_leg_pivot.rotation.x = lerpf(right_leg_pivot.rotation.x, 0.0, delta * 10.0)
		if left_arm_pivot:
			left_arm_pivot.rotation.x = lerpf(left_arm_pivot.rotation.x, sin(idle_cycle * 2.0) * 0.06, delta * 8.0)
		if right_arm_pivot and not is_attacking_anim:
			right_arm_pivot.rotation.x = lerpf(right_arm_pivot.rotation.x, -sin(idle_cycle * 2.0) * 0.06, delta * 8.0)

		visual_mesh.position.y = sin(idle_cycle * 2.4) * 0.02
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
