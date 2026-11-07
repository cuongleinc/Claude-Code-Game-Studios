class_name MainGame
extends Node3D

@onready var game_manager: GameManager = $GameManager
@onready var camera_controller: CameraController = $CameraController
@onready var island_world: IslandWorld = $IslandWorld
@onready var enemy_camp: EnemyCamp = $EnemyCamp
@onready var building_placement: BuildingPlacement = $BuildingPlacement
@onready var hud: RTSHud = $CanvasLayer/RTSHud

var drag_box_start: Vector2 = Vector2.ZERO
var is_drag_selecting: bool = false
var drag_rect: ColorRect

func _ready() -> void:
	building_placement.island_world = island_world

	# Connect HUD signals
	hud.build_requested.connect(_on_build_requested)
	hud.train_unit_requested.connect(_on_train_unit_requested)
	hud.age_advance_requested.connect(_on_age_advance_requested)
	hud.minimap_clicked.connect(_on_minimap_clicked)

	# Connect building placement signal
	building_placement.building_placed.connect(_on_building_placed)

	# Spawn initial player Town Center & Villagers
	spawn_player_starter_base()

	# Selection box visual
	drag_rect = ColorRect.new()
	drag_rect.color = Color(0.2, 0.8, 1.0, 0.25)
	drag_rect.visible = false
	drag_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$CanvasLayer.add_child(drag_rect)

func _process(_delta: float) -> void:
	if Engine.get_process_frames() == 20:
		capture_screenshot()

func capture_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var vp = get_viewport()
	if vp:
		var img = vp.get_texture().get_image()
		if img and not img.is_empty():
			img.save_png("production/qa/evidence/island-empire-gameplay.png")

func spawn_player_starter_base() -> void:
	# Town Center
	var tc = BuildingBase.new()
	add_child(tc)
	tc.setup("town_center", island_world.island1_center, "player", true)
	tc.add_to_group("player_buildings")
	tc.unit_trained.connect(_on_unit_trained)
	game_manager.select_entity(tc)

	# Starter Asian Pagoda House (Reference Image Pavilion Cottage)
	var house = BuildingBase.new()
	add_child(house)
	house.setup("house", island_world.island1_center + Vector3(6.5, 0.0, -3.0), "player", true)
	house.add_to_group("player_buildings")

	# 3 Starting Villagers
	var offsets = [
		Vector3(4.0, 0.5, 2.0),
		Vector3(2.0, 0.5, 4.0),
		Vector3(-3.0, 0.5, 3.0)
	]
	for off in offsets:
		spawn_villager(island_world.island1_center + off)

func spawn_villager(pos: Vector3) -> Villager:
	var v = Villager.new()
	add_child(v)
	v.global_position = pos
	v.add_to_group("player_units")
	return v

func spawn_military_unit(type: String, pos: Vector3) -> MilitaryUnit:
	var u = MilitaryUnit.new()
	u.military_type = type
	u.team = "player"
	add_child(u)
	u.global_position = pos
	u.add_to_group("player_units")
	return u

func spawn_hero_commander(pos: Vector3) -> HeroCommander:
	var hero = HeroCommander.new()
	hero.team = "player"
	add_child(hero)
	hero.global_position = pos
	hero.add_to_group("player_units")
	return hero

func spawn_knight(pos: Vector3) -> RoyalKnight:
	var k = RoyalKnight.new()
	k.team = "player"
	add_child(k)
	k.global_position = pos
	k.add_to_group("player_units")
	return k

func spawn_catapult(pos: Vector3) -> Catapult:
	var cat = Catapult.new()
	cat.team = "player"
	add_child(cat)
	cat.global_position = pos
	cat.add_to_group("player_units")
	return cat

func spawn_transport_ship(pos: Vector3) -> TransportShip:
	var ship = TransportShip.new()
	add_child(ship)
	ship.global_position = pos
	ship.add_to_group("player_ships")
	return ship

func spawn_war_galleon(pos: Vector3) -> WarGalleon:
	var wship = WarGalleon.new()
	add_child(wship)
	wship.global_position = pos
	wship.add_to_group("player_ships")
	return wship

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		capture_screenshot()
		if game_manager:
			game_manager.post_notification("Screenshot saved to production/qa/evidence/!")

	if event is InputEventMouseMotion:
		var mm = event as InputEventMouseMotion
		if building_placement.is_placing:
			var ground_pos = camera_controller.get_ground_position(mm.position)
			building_placement.update_ghost_position(ground_pos)
		elif is_drag_selecting:
			update_drag_box(mm.position)

	elif event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if building_placement.is_placing:
					var ground_pos = camera_controller.get_ground_position(mb.position)
					building_placement.try_place(ground_pos)
				else:
					# Start potential drag-select or single select
					is_drag_selecting = true
					drag_box_start = mb.position
					drag_rect.position = drag_box_start
					drag_rect.size = Vector2.ZERO
					drag_rect.visible = true
			else:
				if is_drag_selecting:
					is_drag_selecting = false
					drag_rect.visible = false
					finish_drag_selection(mb.position)

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if building_placement.is_placing:
				building_placement.cancel_placement()
			else:
				handle_context_command(mb.position)

func update_drag_box(current_mouse: Vector2) -> void:
	var top_left = Vector2(min(drag_box_start.x, current_mouse.x), min(drag_box_start.y, current_mouse.y))
	var size = (current_mouse - drag_box_start).abs()
	drag_rect.position = top_left
	drag_rect.size = size

func finish_drag_selection(release_mouse: Vector2) -> void:
	var drag_dist = drag_box_start.distance_to(release_mouse)
	if drag_dist < 10.0:
		# Single click raycast select
		var entity = raycast_entity(release_mouse)
		if entity:
			game_manager.select_entity(entity)
		else:
			game_manager.clear_selection()
	else:
		# Box select player units
		var rect = Rect2(
			Vector2(min(drag_box_start.x, release_mouse.x), min(drag_box_start.y, release_mouse.y)),
			(release_mouse - drag_box_start).abs()
		)

		var selected_units = []
		var player_units = get_tree().get_nodes_in_group("player_units")
		for u in player_units:
			if is_instance_valid(u) and u is UnitBase:
				var screen_pos = camera_controller.camera.unproject_position(u.global_position)
				if rect.has_point(screen_pos):
					selected_units.append(u)

		if selected_units.size() > 0:
			game_manager.set_selection_group(selected_units)
		else:
			game_manager.clear_selection()

func raycast_entity(screen_pos: Vector2) -> Node3D:
	var cam = camera_controller.camera
	var from = cam.project_ray_origin(screen_pos)
	var to = from + cam.project_ray_normal(screen_pos) * 500.0

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)

	if result.has("collider") and is_instance_valid(result.collider):
		var col = result.collider
		if col.has_meta("entity"):
			return col.get_meta("entity")
	return null

func handle_context_command(screen_pos: Vector2) -> void:
	if game_manager.selected_entities.is_empty():
		return

	var target_entity = raycast_entity(screen_pos)
	var ground_pos = camera_controller.get_ground_position(screen_pos)

	for entity in game_manager.selected_entities:
		if not is_instance_valid(entity):
			continue

		if entity is TransportShip:
			var ship: TransportShip = entity
			ship.command_move_to(ground_pos)

		elif entity is WarGalleon:
			var wship: WarGalleon = entity
			if target_entity is UnitBase and target_entity.team == "enemy":
				wship.command_attack(target_entity)
			elif target_entity is BuildingBase and target_entity.team == "enemy":
				wship.command_attack(target_entity)
			else:
				wship.command_move_to(ground_pos)

		elif entity is Villager:
			var villager: Villager = entity
			if target_entity is ResourceNode:
				villager.command_gather(target_entity)
			elif target_entity is UnitBase and target_entity.team == "enemy":
				villager.command_attack(target_entity)
			elif target_entity is TransportShip:
				target_entity.embark_unit(villager)
			else:
				villager.command_move_to(ground_pos)

		elif entity is MilitaryUnit:
			var mil: MilitaryUnit = entity
			if target_entity is UnitBase and target_entity.team == "enemy":
				mil.command_attack(target_entity)
			elif target_entity is BuildingBase and target_entity.team == "enemy":
				mil.command_attack(target_entity)
			elif target_entity is TransportShip:
				target_entity.embark_unit(mil)
			else:
				mil.command_move_to(ground_pos)

func _on_build_requested(building_type: String) -> void:
	building_placement.start_placement(building_type)

func _on_building_placed(type: String, world_pos: Vector3) -> void:
	var b = BuildingBase.new()
	add_child(b)
	b.setup(type, world_pos, "player", true)
	b.add_to_group("player_buildings")
	b.unit_trained.connect(_on_unit_trained)
	game_manager.post_notification(BuildingData.BUILDINGS[type]["name"] + " constructed!")

func _on_train_unit_requested(unit_type: String, building: BuildingBase) -> void:
	building.queue_unit(unit_type)

func _on_unit_trained(unit_type: String, spawn_pos: Vector3) -> void:
	match unit_type:
		"villager":
			spawn_villager(spawn_pos)
			game_manager.post_notification("New villager ready for work!")
		"spearman":
			spawn_military_unit("spearman", spawn_pos)
			game_manager.post_notification("Spearman armed and ready!")
		"archer":
			spawn_military_unit("archer", spawn_pos)
			game_manager.post_notification("Archer recruited!")
		"knight":
			spawn_knight(spawn_pos)
			game_manager.post_notification("Royal Knight mounted for battle!")
		"catapult":
			spawn_catapult(spawn_pos)
			game_manager.post_notification("Siege Catapult constructed!")
		"hero_commander":
			spawn_hero_commander(spawn_pos)
			game_manager.post_notification("Island Lord has taken the field!")
		"transport_ship":
			var water_dock_pos = spawn_pos + Vector3(2.5, 0.0, 0.0)
			spawn_transport_ship(water_dock_pos)
			game_manager.post_notification("Galley Transport ready to sail!")
		"war_galleon":
			var water_dock_pos = spawn_pos + Vector3(3.5, 0.0, 0.0)
			spawn_war_galleon(water_dock_pos)
			game_manager.post_notification("War Galleon launched!")

func _on_age_advance_requested() -> void:
	game_manager.advance_to_next_age()

func _on_minimap_clicked(world_pos: Vector3) -> void:
	camera_controller.global_position = Vector3(world_pos.x, 0.0, world_pos.z)
