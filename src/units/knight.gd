class_name RoyalKnight
extends MilitaryUnit

func _ready() -> void:
	military_type = "knight"
	unit_name = "Royal Knight"
	max_hp = 260
	attack_damage = 32
	attack_range = 2.4
	attack_cooldown = 1.2
	move_speed = 8.5

	super._ready()
	build_knight_visual()

var horse_root: Node3D
var horse_legs: Array[Node3D] = []

func build_knight_visual() -> void:
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.88, 0.90, 0.94)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.18

	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.82, 0.15)
	gold_mat.metallic = 0.85
	gold_mat.roughness = 0.2

	var white_horse_mat = StandardMaterial3D.new()
	white_horse_mat.albedo_color = Color(0.96, 0.96, 0.98)
	white_horse_mat.roughness = 0.35

	var barding_mat = StandardMaterial3D.new()
	barding_mat.albedo_color = Color(0.16, 0.42, 0.85) if team == "player" else Color(0.85, 0.20, 0.18)
	barding_mat.roughness = 0.4

	var saddle_mat = StandardMaterial3D.new()
	saddle_mat.albedo_color = Color(0.35, 0.22, 0.12)
	saddle_mat.roughness = 0.6

	# 1. 3D Micro-LEGO Warhorse
	horse_root = Node3D.new()
	horse_root.name = "Warhorse"
	visual_mesh.add_child(horse_root)

	# Horse Torso Barrel
	var h_body = MeshInstance3D.new()
	var hb_box = BoxMesh.new()
	hb_box.size = Vector3(0.44, 0.42, 0.85)
	h_body.mesh = hb_box
	h_body.material_override = white_horse_mat
	h_body.position = Vector3(0.0, 0.44, 0.0)
	horse_root.add_child(h_body)

	# Royal Barding Cloth (flank caparison)
	var barding = MeshInstance3D.new()
	var bard_box = BoxMesh.new()
	bard_box.size = Vector3(0.48, 0.28, 0.88)
	barding.mesh = bard_box
	barding.material_override = barding_mat
	barding.position = Vector3(0.0, 0.38, 0.0)
	horse_root.add_child(barding)

	# Horse Neck & Head
	var h_neck = MeshInstance3D.new()
	var hn_box = BoxMesh.new()
	hn_box.size = Vector3(0.24, 0.40, 0.30)
	h_neck.mesh = hn_box
	h_neck.material_override = white_horse_mat
	h_neck.position = Vector3(0.0, 0.68, 0.36)
	h_neck.rotation_degrees.x = -25.0
	horse_root.add_child(h_neck)

	var h_head = MeshInstance3D.new()
	var hh_box = BoxMesh.new()
	hh_box.size = Vector3(0.22, 0.20, 0.32)
	h_head.mesh = hh_box
	h_head.material_override = white_horse_mat
	h_head.position = Vector3(0.0, 0.84, 0.48)
	horse_root.add_child(h_head)

	# 4 Galloping Horse Legs (Pivoting joints)
	horse_legs.clear()
	var leg_coords = [
		Vector3(-0.16, 0.38, 0.30),
		Vector3(0.16, 0.38, 0.30),
		Vector3(-0.16, 0.38, -0.30),
		Vector3(0.16, 0.38, -0.30)
	]
	for pos in leg_coords:
		var leg_pivot = Node3D.new()
		leg_pivot.position = pos
		horse_root.add_child(leg_pivot)
		horse_legs.append(leg_pivot)

		var h_leg = MeshInstance3D.new()
		var hl_box = BoxMesh.new()
		hl_box.size = Vector3(0.11, 0.38, 0.12)
		h_leg.mesh = hl_box
		h_leg.material_override = white_horse_mat
		h_leg.position = Vector3(0.0, -0.19, 0.0)
		leg_pivot.add_child(h_leg)

	# 2. Elevate Knight Minifigure into the Saddle
	if minifig_root:
		minifig_root.position = Vector3(0.0, 0.35, -0.05)
		# Spread legs slightly around the horse flanks
		if left_leg_pivot:
			left_leg_pivot.rotation_degrees = Vector3(30.0, 0.0, 15.0)
		if right_leg_pivot:
			right_leg_pivot.rotation_degrees = Vector3(30.0, 0.0, -15.0)

	# 3. Silver Knight Greathelm with Visor Slit
	if head_node:
		var helm = MeshInstance3D.new()
		var h_cyl = CylinderMesh.new()
		h_cyl.top_radius = 0.14
		h_cyl.bottom_radius = 0.14
		h_cyl.height = 0.24
		helm.mesh = h_cyl
		helm.material_override = steel_mat
		helm.position = Vector3(0.0, 0.06, 0.0)
		head_node.add_child(helm)

		var visor_slit = MeshInstance3D.new()
		var vs_box = BoxMesh.new()
		vs_box.size = Vector3(0.16, 0.03, 0.04)
		var black_mat = StandardMaterial3D.new()
		black_mat.albedo_color = Color(0.05, 0.05, 0.05)
		visor_slit.mesh = vs_box
		visor_slit.material_override = black_mat
		visor_slit.position = Vector3(0.0, 0.06, 0.13)
		head_node.add_child(visor_slit)

	# 4. Heavy Cavalry Lance
	var lance_node = Node3D.new()
	lance_node.name = "CavalryLance"

	var shaft = MeshInstance3D.new()
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.028
	s_cyl.bottom_radius = 0.055
	s_cyl.height = 2.4
	shaft.mesh = s_cyl
	shaft.material_override = gold_mat
	shaft.position = Vector3(0.0, 0.7, 0.0)
	lance_node.add_child(shaft)

	# Lance Tip Point
	var point = MeshInstance3D.new()
	var pt_cone = CylinderMesh.new()
	pt_cone.top_radius = 0.0
	pt_cone.bottom_radius = 0.06
	pt_cone.height = 0.35
	point.mesh = pt_cone
	point.material_override = steel_mat
	point.position = Vector3(0.0, 1.95, 0.0)
	lance_node.add_child(point)

	lance_node.position = Vector3(0.0, -0.05, 0.10)
	lance_node.rotation_degrees = Vector3(45.0, 0.0, 0.0)
	if right_hand_node:
		right_hand_node.add_child(lance_node)
	else:
		visual_mesh.add_child(lance_node)
	weapon_node = lance_node

	# 5. Heraldic Heater Shield on Left Arm
	if left_arm_pivot:
		var shield = MeshInstance3D.new()
		var sh_box = BoxMesh.new()
		sh_box.size = Vector3(0.04, 0.36, 0.24)
		shield.mesh = sh_box
		shield.material_override = barding_mat
		shield.position = Vector3(-0.08, -0.12, 0.08)
		shield.rotation_degrees = Vector3(0.0, 0.0, 15.0)
		left_arm_pivot.add_child(shield)

	# 6. Steed Barding Ground Ring
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.1
	torus.outer_radius = 1.3
	ring.mesh = torus
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.2, 0.5, 0.9, 0.4)
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = r_mat
	ring.position = Vector3(0.0, 0.05, 0.0)
	add_child(ring)

func _process_animations(delta: float) -> void:
	if not visual_mesh or is_dying:
		return

	# Hit flash recovery
	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0 and tunic_node and tunic_mat:
			tunic_node.material_override = tunic_mat

	# Attack lunge
	if is_attacking_anim:
		super._process_animations(delta)
		return

	# Galloping Steed Locomotion
	if velocity.length_squared() > 0.1:
		walk_cycle += delta * move_speed * 1.6
		var gallop = sin(walk_cycle * 2.2)
		visual_mesh.position.y = abs(gallop) * 0.18
		visual_mesh.rotation.z = -sin(walk_cycle) * 0.07
		visual_mesh.rotation.x = 0.12 + gallop * 0.05

		# Animate 4 horse legs in synchronized gallop gait
		if horse_legs.size() == 4:
			horse_legs[0].rotation.x = sin(walk_cycle * 2.2) * 0.60
			horse_legs[1].rotation.x = sin(walk_cycle * 2.2 + 0.5) * 0.60
			horse_legs[2].rotation.x = -sin(walk_cycle * 2.2) * 0.55
			horse_legs[3].rotation.x = -sin(walk_cycle * 2.2 + 0.5) * 0.55

		if weapon_node:
			weapon_node.rotation.x = deg_to_rad(45.0) + gallop * 0.20
	else:
		if horse_legs.size() == 4:
			for hl in horse_legs:
				hl.rotation.x = lerpf(hl.rotation.x, 0.0, delta * 8.0)
		super._process_animations(delta)
