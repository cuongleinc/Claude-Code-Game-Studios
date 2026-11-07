class_name EnemyCamp
extends Node3D

@export var island_center: Vector3 = Vector3(45.0, 0.0, 0.0)
@export var raid_interval: float = 80.0

var raid_timer: float = 0.0
var totem_shrine: BuildingBase
var defenders: Array[MilitaryUnit] = []

func _ready() -> void:
	build_enemy_camp()

func build_enemy_camp() -> void:
	# 1. Chieftain Totem Shrine
	totem_shrine = BuildingBase.new()
	add_child(totem_shrine)
	totem_shrine.setup("totem_shrine", island_center + Vector3(0.0, 0.5, 0.0), "enemy", true)
	totem_shrine.max_hp = 800
	totem_shrine.current_hp = 800

	# Totem visual ornament
	var totem_pole = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.6
	cyl.height = 4.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.2, 0.15)
	totem_pole.mesh = cyl
	totem_pole.material_override = mat
	totem_pole.position = Vector3(0.0, 3.5, 0.0)
	totem_shrine.add_child(totem_pole)

	# 2. Watchtowers
	spawn_watchtower(island_center + Vector3(-10.0, 0.5, -8.0))
	spawn_watchtower(island_center + Vector3(-12.0, 0.5, 8.0))

	# 3. Barbarian Defenders
	var defender_offsets = [
		Vector3(-5.0, 0.5, -4.0),
		Vector3(-4.0, 0.5, 5.0),
		Vector3(4.0, 0.5, -5.0),
		Vector3(5.0, 0.5, 4.0)
	]
	for off in defender_offsets:
		spawn_barbarian(island_center + off)

func spawn_watchtower(pos: Vector3) -> void:
	var tower = BuildingBase.new()
	add_child(tower)
	tower.setup("house", pos, "enemy", true)
	tower.max_hp = 400
	tower.current_hp = 400

func spawn_barbarian(pos: Vector3) -> MilitaryUnit:
	var barb = MilitaryUnit.new()
	barb.military_type = "barbarian"
	barb.team = "enemy"
	add_child(barb)
	barb.global_position = pos
	defenders.append(barb)
	return barb


func _process(delta: float) -> void:
	raid_timer += delta
	if raid_timer >= raid_interval:
		raid_timer = 0.0
		launch_raid()

	# Defender AI: check if any player units entered enemy island perimeter
	var player_units = get_tree().get_nodes_in_group("player_units")
	for barb in defenders:
		if is_instance_valid(barb) and barb.state == UnitBase.State.IDLE:
			for pu in player_units:
				if is_instance_valid(pu) and barb.global_position.distance_to(pu.global_position) <= 18.0:
					barb.command_attack(pu)
					break

func launch_raid() -> void:
	if GameManager.instance:
		GameManager.instance.post_notification("ALERT: Barbarian war party spotted sailing to your island!")

	# Spawn landing party on player island shore
	var landing_beach = Vector3(-4.0, 0.5, 0.0)
	for i in range(3):
		var barb = spawn_barbarian(landing_beach + Vector3(0.0, 0.0, float(i) * 2.0 - 2.0))
		# Command to attack nearest player building or villager
		var p_buildings = get_tree().get_nodes_in_group("player_buildings")
		if p_buildings.size() > 0:
			barb.command_attack(p_buildings[0])
