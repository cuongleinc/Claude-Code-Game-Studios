class_name MinimapRadar
extends Control

signal map_position_clicked(world_target: Vector3)

# Map world bounds: Player island is around x: -50, Enemy island is around x: 90
var world_min: Vector2 = Vector2(-120.0, -75.0)
var world_max: Vector2 = Vector2(150.0, 75.0)
var is_dragging: bool = false

# Topography landmarks
var player_island_center: Vector3 = Vector3(-50.0, 0.0, 0.0)
var enemy_island_center: Vector3 = Vector3(90.0, 0.0, 0.0)
var quarry_pos: Vector3 = Vector3(-28.0, 0.0, -22.0)
var monolith_pos: Vector3 = Vector3(-72.0, 0.0, 24.0)

func _ready() -> void:
	custom_minimum_size = Vector2(175, 145)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_dragging = true
				pan_to_click(mb.position)
			else:
				is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		pan_to_click(event.position)

func pan_to_click(click_pos: Vector2) -> void:
	var norm_x = clamp(click_pos.x / size.x, 0.0, 1.0)
	var norm_y = clamp(click_pos.y / size.y, 0.0, 1.0)

	var world_x = lerp(world_min.x, world_max.x, norm_x)
	var world_z = lerp(world_min.y, world_max.y, norm_y)
	emit_signal("map_position_clicked", Vector3(world_x, 0.0, world_z))

func focus_on_capital() -> void:
	emit_signal("map_position_clicked", player_island_center)

func focus_on_enemy() -> void:
	emit_signal("map_position_clicked", enemy_island_center)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# 1. Ocean background with subtle depth gradient
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.12, 0.20, 0.94))

	# 2. Subtle navigational bathymetry grid
	for i in range(1, 4):
		var gx = (size.x / 4.0) * i
		draw_line(Vector2(gx, 0), Vector2(gx, size.y), Color(0.12, 0.25, 0.35, 0.25), 1.0)
		var gy = (size.y / 4.0) * i
		draw_line(Vector2(0, gy), Vector2(size.x, gy), Color(0.12, 0.25, 0.35, 0.25), 1.0)

	# 3. Island 1 (Player Island: Center around -50, 0, Radius 50)
	var p1 = world_to_map(player_island_center)
	var r1 = (50.0 / (world_max.x - world_min.x)) * size.x
	# Coastal Shallow Waters / Reefs
	draw_circle(p1, r1 + 3.5, Color(0.18, 0.45, 0.55, 0.4))
	# Sandy Shoreline
	draw_circle(p1, r1 + 1.2, Color(0.86, 0.80, 0.54, 0.85))
	# Lush Grass Capital Plateau
	draw_circle(p1, r1 - 1.5, Color(0.24, 0.58, 0.32, 0.95))

	# Mountain Quarry & Gold Basin Zone (Elevated Rocky Terrace)
	var q_pos = world_to_map(quarry_pos)
	draw_circle(q_pos, 7.5, Color(0.34, 0.32, 0.30, 0.95))
	draw_circle(q_pos, 4.0, Color(0.85, 0.72, 0.22, 0.9))

	# Ancient Monolith Bluff (Sacred Landmark)
	var m_pos = world_to_map(monolith_pos)
	draw_circle(m_pos, 5.0, Color(0.42, 0.40, 0.45, 0.95))
	draw_circle(m_pos, 2.0, Color(0.95, 0.85, 0.3, 0.95))

	# 4. Island 2 (Enemy Island: Center around 90, 0, Radius 45)
	var p2 = world_to_map(enemy_island_center)
	var r2 = (45.0 / (world_max.x - world_min.x)) * size.x
	# Dark Coastal Shallows
	draw_circle(p2, r2 + 3.0, Color(0.22, 0.26, 0.32, 0.4))
	# Ash Sand Rim
	draw_circle(p2, r2 + 1.0, Color(0.55, 0.50, 0.45, 0.8))
	# Volcanic Ash Plateau
	draw_circle(p2, r2 - 1.5, Color(0.35, 0.30, 0.28, 0.95))
	# Totem Red Sanctum
	draw_circle(p2, 4.5, Color(0.85, 0.18, 0.15, 0.95))

	# 5. Resource Nodes
	var resources = get_tree().get_nodes_in_group("resource_nodes")
	for res in resources:
		if is_instance_valid(res) and res is Node3D:
			var mpos = world_to_map(res.global_position)
			var col = Color(0.2, 0.85, 0.35) if res.resource_type == "wood" else (Color(0.7, 0.72, 0.78) if res.resource_type == "stone" else Color(1.0, 0.85, 0.2))
			draw_circle(mpos, 1.6, col)

	# 6. Player Buildings
	var p_buildings = get_tree().get_nodes_in_group("player_buildings")
	for b in p_buildings:
		if is_instance_valid(b) and b is Node3D:
			var mpos = world_to_map(b.global_position)
			draw_rect(Rect2(mpos - Vector2(3, 3), Vector2(6, 6)), Color(0.22, 0.60, 0.98))
			draw_rect(Rect2(mpos - Vector2(3, 3), Vector2(6, 6)), Color(1.0, 1.0, 1.0, 0.6), false, 1.0)

	# 7. Enemy Buildings
	var e_buildings = get_tree().get_nodes_in_group("enemy_buildings")
	for b in e_buildings:
		if is_instance_valid(b) and b is Node3D:
			var mpos = world_to_map(b.global_position)
			draw_rect(Rect2(mpos - Vector2(3, 3), Vector2(6, 6)), Color(0.95, 0.22, 0.22))
			draw_rect(Rect2(mpos - Vector2(3, 3), Vector2(6, 6)), Color(1.0, 0.8, 0.8, 0.6), false, 1.0)

	# 8. Player Units & Ships
	var p_units = get_tree().get_nodes_in_group("player_units")
	for u in p_units:
		if is_instance_valid(u) and u is Node3D:
			var mpos = world_to_map(u.global_position)
			draw_circle(mpos, 2.2, Color(0.2, 0.9, 1.0))

	var p_ships = get_tree().get_nodes_in_group("player_ships")
	for s in p_ships:
		if is_instance_valid(s) and s is Node3D:
			var mpos = world_to_map(s.global_position)
			draw_circle(mpos, 3.2, Color(0.2, 0.9, 1.0))

	# 9. Enemy Units
	var e_units = get_tree().get_nodes_in_group("enemy_units")
	for u in e_units:
		if is_instance_valid(u) and u is Node3D:
			var mpos = world_to_map(u.global_position)
			draw_circle(mpos, 2.4, Color(1.0, 0.25, 0.25))

	# 10. Camera Viewport Indicator
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_pos = cam.global_position
		var cpos = world_to_map(Vector3(cam_pos.x, 0.0, cam_pos.z - 16.0))
		draw_rect(Rect2(cpos - Vector2(16, 11), Vector2(32, 22)), Color(1.0, 0.9, 0.35, 0.85), false, 1.5)

	# 11. Compass Rose Studs & Bezel
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.72, 0.62, 0.32), false, 2.0)
	# Corner LEGO Studs
	draw_circle(Vector2(6, 6), 2.2, Color(0.85, 0.75, 0.4))
	draw_circle(Vector2(size.x - 6, 6), 2.2, Color(0.85, 0.75, 0.4))
	draw_circle(Vector2(6, size.y - 6), 2.2, Color(0.85, 0.75, 0.4))
	draw_circle(Vector2(size.x - 6, size.y - 6), 2.2, Color(0.85, 0.75, 0.4))

func world_to_map(world_pos: Vector3) -> Vector2:
	var norm_x = (world_pos.x - world_min.x) / (world_max.x - world_min.x)
	var norm_y = (world_pos.z - world_min.y) / (world_max.y - world_min.y)
	return Vector2(norm_x * size.x, norm_y * size.y)
