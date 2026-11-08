class_name CameraController
extends Node3D

@export var move_speed: float = 28.0
@export var zoom_speed: float = 14.0
@export var min_zoom: float = 10.0
@export var max_zoom: float = 90.0
@export var rotate_speed: float = 2.0

@export var min_bounds: Vector2 = Vector2(-150.0, -120.0)
@export var max_bounds: Vector2 = Vector2(170.0, 120.0)

@onready var pitch_pivot: Node3D = $PitchPivot
@onready var camera: Camera3D = $PitchPivot/Camera3D

var current_zoom: float = 42.0
var target_zoom: float = 42.0
var is_dragging: bool = false
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_cam_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	target_zoom = clamp(camera.position.z, min_zoom, max_zoom)
	current_zoom = target_zoom

func _process(delta: float) -> void:
	handle_keyboard_movement(delta)
	handle_smooth_zoom(delta)

func handle_keyboard_movement(delta: float) -> void:
	var move_vec = Vector3.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_vec.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_vec.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_vec.z += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_vec.z -= 1.0

	# Rotation via Q / E
	if Input.is_key_pressed(KEY_Q):
		rotate_y(rotate_speed * delta)
	if Input.is_key_pressed(KEY_E):
		rotate_y(-rotate_speed * delta)

	if move_vec.length_squared() > 0.0:
		move_vec = move_vec.normalized()
		var forward = -transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right = transform.basis.x
		right.y = 0.0
		right = right.normalized()

		var world_move = (forward * -move_vec.z + right * move_vec.x) * move_speed * delta
		global_position += world_move
		clamp_position()

func handle_smooth_zoom(delta: float) -> void:
	current_zoom = lerp(current_zoom, target_zoom, delta * 8.0)
	camera.position.z = current_zoom

func clamp_position() -> void:
	global_position.x = clamp(global_position.x, min_bounds.x, max_bounds.x)
	global_position.z = clamp(global_position.z, min_bounds.y, max_bounds.y)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom - zoom_speed * 0.4, min_zoom, max_zoom)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom + zoom_speed * 0.4, min_zoom, max_zoom)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				is_dragging = true
				drag_start_mouse_pos = mb.position
				drag_start_cam_pos = global_position
			else:
				is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		var mm = event as InputEventMouseMotion
		var diff = mm.position - drag_start_mouse_pos
		var right = transform.basis.x
		var forward = -transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		right.y = 0.0
		right = right.normalized()

		var factor = (current_zoom / 25.0) * 0.035
		global_position = drag_start_cam_pos - (right * diff.x + forward * -diff.y) * factor
		clamp_position()

func get_ground_position(screen_pos: Vector2) -> Vector3:
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_dir = camera.project_ray_normal(screen_pos)
	var ground_plane = Plane(Vector3.UP, 0.0)
	var intersection = ground_plane.intersects_ray(ray_origin, ray_dir)
	if intersection != null:
		return intersection
	return Vector3.ZERO
