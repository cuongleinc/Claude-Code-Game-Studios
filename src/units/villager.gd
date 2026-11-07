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
	# Straw cone hat
	var hat = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.04
	cone.bottom_radius = 0.44
	cone.height = 0.22
	var hmat = StandardMaterial3D.new()
	hmat.albedo_color = Color(0.85, 0.75, 0.42)
	hat.mesh = cone
	hat.material_override = hmat
	hat.position = Vector3(0.0, 1.34, 0.0)
	visual_mesh.add_child(hat)

	# Woodcutter small axe in hand
	var axe = MeshInstance3D.new()
	var abox = BoxMesh.new()
	abox.size = Vector3(0.08, 0.55, 0.08)
	var amat = StandardMaterial3D.new()
	amat.albedo_color = Color(0.45, 0.3, 0.15)
	axe.mesh = abox
	axe.material_override = amat
	axe.position = Vector3(0.35, 0.5, 0.1)
	axe.rotation_degrees.x = 25.0
	visual_mesh.add_child(axe)

	# Add backpack indicator
	backpack_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.4, 0.45, 0.3)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.65, 0.45, 0.25)
	backpack_mesh.mesh = box
	backpack_mesh.material_override = mat
	backpack_mesh.position = Vector3(0.0, 0.8, -0.35)
	backpack_mesh.visible = false
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
		gather_timer += delta
		if gather_timer >= 1.0:
			gather_timer = 0.0
			var harvested = gather_target.harvest(2)
			carried_type = gather_target.resource_type
			carried_amount += harvested
			backpack_mesh.visible = true

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
