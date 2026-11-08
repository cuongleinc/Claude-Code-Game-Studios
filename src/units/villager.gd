class_name Villager
extends UnitBase

var carried_type: String = ""
var carried_amount: int = 0
var max_carry: int = 10
var gather_timer: float = 0.0
var gather_target: ResourceNode
var dropoff_target: Node3D
var backpack_mesh: MeshInstance3D

func _ready() -> void:
	unit_name = "Villager"
	max_hp = 60
	move_speed = 5.5
	super._ready()
	build_villager_visual()

func build_villager_visual() -> void:
	# 1. Straw Conical Farmer Hat atop head stud
	var hat = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.04
	cone.bottom_radius = 0.32
	cone.height = 0.16
	var hmat = StandardMaterial3D.new()
	hmat.albedo_color = Color(0.88, 0.76, 0.42)
	hmat.roughness = 0.8
	hat.mesh = cone
	hat.material_override = hmat
	hat.position = Vector3(0.0, 0.16, 0.0)
	if head_node:
		head_node.add_child(hat)
	else:
		hat.position = Vector3(0.0, 1.25, 0.0)
		visual_mesh.add_child(hat)

	# 2. Woodcutter / Miner Axe mounted in C-Clamp Hand
	var axe_node = Node3D.new()
	axe_node.name = "VillagerTool"
	
	# Wood handle
	var handle = MeshInstance3D.new()
	var h_cyl = CylinderMesh.new()
	h_cyl.top_radius = 0.022
	h_cyl.bottom_radius = 0.022
	h_cyl.height = 0.48
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.48, 0.30, 0.15)
	handle.mesh = h_cyl
	handle.material_override = h_mat
	axe_node.add_child(handle)

	# Silver steel blade
	var blade = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.04, 0.14, 0.14)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.85, 0.88, 0.92)
	b_mat.metallic = 0.8
	b_mat.roughness = 0.25
	blade.mesh = b_box
	blade.material_override = b_mat
	blade.position = Vector3(0.0, 0.16, 0.07)
	axe_node.add_child(blade)

	axe_node.position = Vector3(0.0, -0.06, 0.08)
	axe_node.rotation_degrees = Vector3(45.0, 0.0, 0.0)
	if right_hand_node:
		right_hand_node.add_child(axe_node)
	elif right_arm_pivot:
		right_arm_pivot.add_child(axe_node)
	else:
		visual_mesh.add_child(axe_node)
	weapon_node = axe_node

	# 3. Micro-LEGO Backpack Indicator on back of torso
	backpack_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.26, 0.30, 0.14)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.35, 0.18)
	backpack_mesh.mesh = box
	backpack_mesh.material_override = mat
	backpack_mesh.position = Vector3(0.0, 0.0, -0.15)
	backpack_mesh.visible = false
	if torso_node:
		torso_node.add_child(backpack_mesh)
	else:
		backpack_mesh.position = Vector3(0.0, 0.8, -0.25)
		visual_mesh.add_child(backpack_mesh)

func command_gather(node: ResourceNode) -> void:
	gather_target = node
	target_entity = null
	state = State.GATHERING

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	match state:
		State.GATHERING:
			handle_gathering(delta)
		State.DELIVERING:
			handle_delivering(delta)

func handle_gathering(delta: float) -> void:
	if not is_instance_valid(gather_target):
		find_nearby_resource_of_type(carried_type)
		return

	var dist = global_position.distance_to(gather_target.global_position)
	if dist > 1.8:
		var dir = (gather_target.global_position - global_position).normalized()
		dir.y = 0.0
		velocity = dir * move_speed
		look_at_safe(gather_target.global_position)
	else:
		velocity = Vector3.ZERO
		look_at_safe(gather_target.global_position)
		gather_timer += delta

		# Rhythmic woodcutting / mining chopping animation with Minifig arm!
		if right_arm_pivot:
			right_arm_pivot.rotation.x = deg_to_rad(-40.0) + sin(gather_timer * 11.0) * deg_to_rad(55.0)
		elif weapon_node:
			weapon_node.rotation.x = deg_to_rad(25.0) + sin(gather_timer * 11.0) * 0.75
		if visual_mesh:
			visual_mesh.rotation.x = sin(gather_timer * 11.0) * 0.08

		if gather_timer >= 1.0:
			gather_timer = 0.0
			var harvested = gather_target.harvest(2)
			carried_type = gather_target.resource_type
			carried_amount += harvested
			backpack_mesh.visible = true

			# Floating harvest gain indicator
			if is_inside_tree() and get_parent():
				var ft = FloatingText.new()
				get_parent().add_child(ft)
				var c = Color(0.3, 0.9, 0.3) if carried_type == "food" else (Color(0.8, 0.6, 0.2) if carried_type == "wood" else Color(0.8, 0.8, 0.8))
				ft.setup(global_position + Vector3(0.0, 1.8, 0.0), "+%d %s" % [harvested, carried_type.capitalize()], c)

			if carried_amount >= max_carry:
				state = State.DELIVERING
				find_dropoff()

func handle_delivering(delta: float) -> void:
	if not is_instance_valid(dropoff_target):
		find_dropoff()
		if not is_instance_valid(dropoff_target):
			state = State.IDLE
			velocity = Vector3.ZERO
			return

	var dist = global_position.distance_to(dropoff_target.global_position)
	if dist > 3.0:
		var dir = (dropoff_target.global_position - global_position).normalized()
		dir.y = 0.0
		velocity = dir * move_speed
		look_at_safe(dropoff_target.global_position)
	else:
		# Deliver!
		velocity = Vector3.ZERO
		if GameManager.instance:
			GameManager.instance.add_resource(carried_type, carried_amount)
		carried_amount = 0
		backpack_mesh.visible = false

		# Return to gather
		if is_instance_valid(gather_target):
			state = State.GATHERING
		else:
			find_nearby_resource_of_type(carried_type)

func find_dropoff() -> void:
	var buildings = get_tree().get_nodes_in_group("player_buildings")
	var nearest: Node3D = null
	var min_dist = 99999.0
	for b in buildings:
		if b is BuildingBase and b.team == "player" and b.building_type in ["town_center", "lumber_camp"]:
			var d = global_position.distance_squared_to(b.global_position)
			if d < min_dist:
				min_dist = d
				nearest = b
	dropoff_target = nearest

func find_nearby_resource_of_type(type: String) -> void:
	var nodes = get_tree().get_nodes_in_group("resource_nodes")
	var nearest: ResourceNode = null
	var min_dist = 99999.0
	for n in nodes:
		if n is ResourceNode and (type == "" or n.resource_type == type) and n.amount_remaining > 0:
			var d = global_position.distance_squared_to(n.global_position)
			if d < min_dist:
				min_dist = d
				nearest = n
	if nearest:
		command_gather(nearest)
	else:
		state = State.IDLE
		velocity = Vector3.ZERO
