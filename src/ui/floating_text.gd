class_name FloatingText
extends Node3D

var text: String = ""
var color: Color = Color(1.0, 0.9, 0.2)
var velocity: Vector3 = Vector3(0.0, 2.5, 0.0)
var lifetime: float = 0.9
var elapsed: float = 0.0
var label: Label3D

func setup(pos: Vector3, p_text: String, p_color: Color = Color(1.0, 0.9, 0.2)) -> void:
	text = p_text
	color = p_color
	position = pos

func _ready() -> void:
	label = Label3D.new()
	label.text = text
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	label.outline_size = 8
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
	add_child(label)

func _process(delta: float) -> void:
	elapsed += delta
	position += velocity * delta
	velocity.y -= 1.2 * delta

	if label:
		var alpha = clamp(1.0 - (elapsed / lifetime), 0.0, 1.0)
		label.modulate.a = alpha
		label.outline_modulate.a = alpha

	if elapsed >= lifetime:
		queue_free()
