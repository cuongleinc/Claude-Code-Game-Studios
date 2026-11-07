class_name EnemyCamp
extends Node3D

@export var island_center: Vector3 = Vector3(45.0, 0.0, 0.0)
@export var raid_interval: float = 65.0

var raid_timer: float = 0.0
var raid_wave_count: int = 0
var totem_shrine: BuildingBase
var chieftain_boss: MilitaryUnit
var defenders: Array[MilitaryUnit] = []

func _ready() -> void:
	build_enemy_camp()

func build_enemy_camp() -> void:
	# 1. Chieftain Totem Shrine
	totem_shrine = BuildingBase.new()
	add_child(totem_shrine)
	totem_shrine.setup("totem_shrine", island_center + Vector3(0.0, 0.5, 0.0), "enemy", true)
	totem_shrine.max_hp = 1000
	totem_shrine.current_hp = 1000

	# Totem pole decoration
	var totem_pole = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.6
	cyl.height = 4.2
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.2, 0.15)
	totem_pole.mesh = cyl
	totem_pole.material_override = mat
	totem_pole.position = Vector3(0.0, 3.5, 0.0)
	totem_shrine.add_child(totem_pole)

	# 2. Ash Isle Chieftain Boss guarding the shrine
	chieftain_boss = spawn_enemy("clan_chieftain", island_center + Vector3(0.0, 0.5, 3.0))

	# 3. Watchtowers
	spawn_watchtower(island_center + Vector3(-10.0, 0.5, -8.0))
	spawn_watchtower(island_center + Vector3(-12.0, 0.5, 8.0))

	# 4. Starting Clan Berserkers
	var defender_offsets = [
		Vector3(-5.0, 0.5, -4.0),
		Vector3(-4.0, 0.5, 5.0),
		Vector3(4.0, 0.5, -5.0),
		Vector3(5.0, 0.5, 4.0)
	]
	for off in defender_offsets:
		spawn_enemy("clan_berserker", island_center + off)

func spawn_watchtower(pos: Vector3) -> void:
	var tower = BuildingBase.new()
	add_child(tower)
	tower.setup("house", pos, "enemy", true)
	tower.max_hp = 450
	tower.current_hp = 450

func spawn_enemy(type: String, pos: Vector3) -> MilitaryUnit:
	var unit = MilitaryUnit.new()
	unit.military_type = type
	unit.team = "enemy"
	add_child(unit)
	unit.global_position = pos
	defenders.append(unit)
	return unit

func _process(delta: float) -> void:
	raid_timer += delta
	if raid_timer >= raid_interval:
		raid_timer = 0.0
		launch_raid()

	# Defender AI: protect island perimeter
	var player_units = get_tree().get_nodes_in_group("player_units")
	for unit in defenders:
		if is_instance_valid(unit) and unit.state == UnitBase.State.IDLE:
			for pu in player_units:
				if is_instance_valid(pu) and unit.global_position.distance_to(pu.global_position) <= 20.0:
					unit.command_attack(pu)
					break

func launch_raid() -> void:
	raid_wave_count += 1
	var landing_beach = Vector3(-4.0, 0.5, 0.0)
	var p_buildings = get_tree().get_nodes_in_group("player_buildings")
	var target_target = p_buildings[0] if p_buildings.size() > 0 else null

	if raid_wave_count % 3 == 0:
		# Dread Captain Boss Wave!
		if GameManager.instance:
			GameManager.instance.post_notification("⚠️ DANGER: Dread Captain Flint and his Corsair fleet are attacking your shore!")
		var boss = spawn_enemy("dread_captain", landing_beach + Vector3(0.0, 0.0, 0.0))
		if target_target:
			boss.command_attack(target_target)

		for i in range(3):
			var raider = spawn_enemy("corsair_raider", landing_beach + Vector3(-1.5, 0.0, float(i) * 2.5 - 2.5))
			if target_target:
				raider.command_attack(target_target)

	elif raid_wave_count % 2 == 0:
		# Corsair Raider Wave
		if GameManager.instance:
			GameManager.instance.post_notification("ALERT: Red Corsair Pirates landed on your western shore!")
		for i in range(3):
			var raider = spawn_enemy("corsair_raider", landing_beach + Vector3(0.0, 0.0, float(i) * 2.0 - 2.0))
			if target_target:
				raider.command_attack(target_target)
	else:
		# Clan Berserker Wave
		if GameManager.instance:
			GameManager.instance.post_notification("ALERT: Ash Isle Clan war party attacking!")
		for i in range(3):
			var barb = spawn_enemy("clan_berserker", landing_beach + Vector3(0.0, 0.0, float(i) * 2.0 - 2.0))
			if target_target:
				barb.command_attack(target_target)
