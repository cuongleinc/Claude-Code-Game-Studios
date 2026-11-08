class_name MinimapRadar
extends Control

signal map_position_clicked(world_target: Vector3)

# Map world bounds: Player island is around x: -50, Enemy island is around x: 90
var world_min: Vector2 = Vector2(-120.0, -75.0)
var world_max: Vector2 = Vector2(150.0, 75.0)
var is_dragging: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(160, 140)
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

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Ocean background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.16, 0.24, 0.95))

	# Subtle grid
	for i in range(1, 4):
		var gx = (size.x / 4.0) * i
		draw_line(Vector2(gx, 0), Vector2(gx, size.y), Color(0.12, 0.28, 0.38, 0.4), 1.0)
		var gy = (size.y / 4.0) * i
		draw_line(Vector2(0, gy), Vector2(size.x, gy), Color(0.12, 0.28, 0.38, 0.4), 1.0)

	# Draw Island 1 (Player Island: Center around -50, 0, Radius 50)
	var p1 = world_to_map(Vector3(-50.0, 0.0, 0.0))
	var r1 = (50.0 / (world_max.x - world_min.x)) * size.x
	draw_circle(p1, r1 + 2.0, Color(0.85, 0.8, 0.55, 0.6)) # Sand
	draw_circle(p1, r1 - 1.0, Color(0.25, 0.55, 0.3, 0.85)) # Grass

	# Draw Island 2 (Enemy Island: Center around 90, 0, Radius 45)
	var p2 = world_to_map(Vector3(90.0, 0.0, 0.0))
	var r2 = (45.0 / (world_max.x - world_min.x)) * size.x
	draw_circle(p2, r2 + 2.0, Color(0.7, 0.65, 0.5, 0.6))
	draw_circle(p2, r2 - 1.0, Color(0.38, 0.35, 0.3, 0.85))

	# Draw Resource Nodes
	var resources = get_tree().get_nodes_in_group("resource_nodes")
	for res in resources:
		if is_instance_valid(res) and res is Node3D:
			var mpos = world_to_map(res.global_position)
			var col = Color(0.2, 0.8, 0.3) if res.resource_type == "wood" else (Color(0.65, 0.65, 0.7) if res.resource_type == "stone" else Color(1.0, 0.85, 0.2))
			draw_circle(mpos, 1.8, col)

	# Draw Player Buildings
	var p_buildings = get_tree().get_nodes_in_group("player_buildings")
	for b in p_buildings:
		if is_instance_valid(b) and b is Node3D:
			var mpos = world_to_map(b.global_position)
			draw_rect(Rect2(mpos - Vector2(3, 3), Vector2(6, 6)), Color(0.2, 0.5, 0.95))

	# Draw Enemy Buildings
	var e_buildings = get_tree().get_nodes_in_group("enemy_buildings")
	for b in e_buildings:
		if is_instance_valid(b) and b is Node3D:
			var mpos = world_to_map(b.global_position)
			draw_rect(Rect2(mpos - Vector2(3, 3), Vector2(6, 6)), Color(0.9, 0.2, 0.2))

	# Draw Player Units & Ships
	var p_units = get_tree().get_nodes_in_group("player_units")
	for u in p_units:
		if is_instance_valid(u) and u is Node3D:
			var mpos = world_to_map(u.global_position)
			draw_circle(mpos, 2.4, Color(0.2, 0.9, 1.0))

	var p_ships = get_tree().get_nodes_in_group("player_ships")
	for s in p_ships:
		if is_instance_valid(s) and s is Node3D:
			var mpos = world_to_map(s.global_position)
			draw_circle(mpos, 3.2, Color(0.2, 0.9, 1.0))

	# Draw Enemy Units
	var e_units = get_tree().get_nodes_in_group("enemy_units")
	for u in e_units:
		if is_instance_valid(u) and u is Node3D:
			var mpos = world_to_map(u.global_position)
			draw_circle(mpos, 2.6, Color(1.0, 0.25, 0.25))

	# Draw Camera Viewport indicator
	var cam = get_viewport().get_camera_3d()
	if cam:
		var cam_pos = cam.global_position
		var cpos = world_to_map(Vector3(cam_pos.x, 0.0, cam_pos.z - 16.0))
		draw_rect(Rect2(cpos - Vector2(14, 10), Vector2(28, 20)), Color(1.0, 0.9, 0.3, 0.7), false, 1.5)

	# Ornate Outer Border
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.65, 0.55, 0.25), false, 2.0)

func world_to_map(world_pos: Vector3) -> Vector2:
	var norm_x = (world_pos.x - world_min.x) / (world_max.x - world_min.x)
	var norm_y = (world_pos.z - world_min.y) / (world_max.y - world_min.y)
	return Vector2(norm_x * size.x, norm_y * size.y)
