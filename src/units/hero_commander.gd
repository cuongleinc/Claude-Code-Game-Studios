class_name HeroCommander
extends MilitaryUnit

@export var aura_radius: float = 12.0
var aura_timer: float = 0.0

func _ready() -> void:
	military_type = "hero"
	unit_name = "Island Lord"
	max_hp = 300
	attack_damage = 28
	attack_range = 2.2
	attack_cooldown = 1.0
	move_speed = 6.4

	super._ready()
	build_hero_visual()

func build_hero_visual() -> void:
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(1.0, 0.84, 0.12)
	gold_mat.metallic = 0.9
	gold_mat.roughness = 0.15

	var ruby_mat = StandardMaterial3D.new()
	ruby_mat.albedo_color = Color(0.95, 0.12, 0.15)
	ruby_mat.roughness = 0.1

	var cape_mat = StandardMaterial3D.new()
	cape_mat.albedo_color = Color(0.75, 0.12, 0.15)
	cape_mat.roughness = 0.65

	# 1. Imperial Golden Crown on head stud
	if head_node:
		var crown_base = MeshInstance3D.new()
		var cb_cyl = CylinderMesh.new()
		cb_cyl.top_radius = 0.14
		cb_cyl.bottom_radius = 0.14
		cb_cyl.height = 0.08
		crown_base.mesh = cb_cyl
		crown_base.material_override = gold_mat
		crown_base.position = Vector3(0.0, 0.12, 0.0)
		head_node.add_child(crown_base)

		# 4 Golden Spires
		for angle_deg in [0.0, 90.0, 180.0, 270.0]:
			var spire = MeshInstance3D.new()
			var sp_cone = CylinderMesh.new()
			sp_cone.top_radius = 0.0
			sp_cone.bottom_radius = 0.03
			sp_cone.height = 0.12
			spire.mesh = sp_cone
			spire.material_override = gold_mat
			var rad = deg_to_rad(angle_deg)
			spire.position = Vector3(cos(rad) * 0.12, 0.18, sin(rad) * 0.12)
			head_node.add_child(spire)

		# Center Crown Ruby Gem
		var ruby = MeshInstance3D.new()
		var r_sphere = SphereMesh.new()
		r_sphere.radius = 0.025
		r_sphere.height = 0.05
		ruby.mesh = r_sphere
		ruby.material_override = ruby_mat
		ruby.position = Vector3(0.0, 0.14, 0.135)
		head_node.add_child(ruby)

	# 2. Flowing Royal Velvet Cape draped behind Torso
	if torso_node:
		var cape = MeshInstance3D.new()
		var cape_box = BoxMesh.new()
		cape_box.size = Vector3(0.36, 0.52, 0.03)
		cape.mesh = cape_box
		cape.material_override = cape_mat
		cape.position = Vector3(0.0, -0.06, -0.13)
		cape.rotation_degrees.x = 8.0
		torso_node.add_child(cape)

	# 3. Imperial Sunfire Broadsword
	var sword_node = Node3D.new()
	sword_node.name = "ImperialBroadsword"

	var blade = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.04, 0.85, 0.10)
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.9, 0.95, 1.0)
	steel_mat.metallic = 0.9
	steel_mat.roughness = 0.15
	blade.mesh = b_box
	blade.material_override = steel_mat
	blade.position = Vector3(0.0, 0.35, 0.0)
	sword_node.add_child(blade)

	var crossguard = MeshInstance3D.new()
	var cg_box = BoxMesh.new()
	cg_box.size = Vector3(0.06, 0.05, 0.26)
	crossguard.mesh = cg_box
	crossguard.material_override = gold_mat
	crossguard.position = Vector3(0.0, -0.04, 0.0)
	sword_node.add_child(crossguard)

	sword_node.position = Vector3(0.0, -0.06, 0.08)
	sword_node.rotation_degrees = Vector3(30.0, 0.0, 0.0)
	if right_hand_node:
		right_hand_node.add_child(sword_node)
	else:
		visual_mesh.add_child(sword_node)
	weapon_node = sword_node

	# 4. Golden Commander Aura Ring on Ground
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = aura_radius - 0.2
	torus.outer_radius = aura_radius
	ring.mesh = torus
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(1.0, 0.85, 0.2, 0.3)
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = r_mat
	ring.position = Vector3(0.0, 0.05, 0.0)
	add_child(ring)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Aura tick
	aura_timer += delta
	if aura_timer >= 1.0:
		aura_timer = 0.0
		buff_nearby_allies()

func buff_nearby_allies() -> void:
	var allies = get_tree().get_nodes_in_group("player_units")
	for ally in allies:
		if ally is UnitBase and ally != self:
			if global_position.distance_to(ally.global_position) <= aura_radius:
				# Temporarily buff attack damage
				ally.attack_damage = int(ally.attack_damage * 1.0) # Active commander presence
