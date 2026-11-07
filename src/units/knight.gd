class_name RoyalKnight
extends MilitaryUnit

func _ready() -> void:
	military_type = "knight"
	unit_name = "Royal Knight"
	max_hp = 260
	attack_damage = 32
	attack_range = 2.4
	attack_cooldown = 1.2
	move_speed = 8.5

	super._ready()
	build_knight_visual()

func build_knight_visual() -> void:
	var sprite_path = "res://assets/characters/royal_knight.png"
	if ResourceLoader.exists(sprite_path):
		var tex = load(sprite_path)
		var sprite = Sprite3D.new()
		sprite.texture = tex
		sprite.pixel_size = 0.025
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.position = Vector3(0.0, 1.4, 0.0)
		visual_mesh.add_child(sprite)

	# Steed Barding Aura
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.1
	torus.outer_radius = 1.3
	ring.mesh = torus
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(0.2, 0.5, 0.9, 0.4)
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = r_mat
	ring.position = Vector3(0.0, 0.05, 0.0)
	add_child(ring)
