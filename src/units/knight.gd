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

	# Knight Cavalry Lance
	var lance = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.03
	cyl.bottom_radius = 0.07
	cyl.height = 2.4
	var l_mat = StandardMaterial3D.new()
	l_mat.albedo_color = Color(0.9, 0.8, 0.3)
	l_mat.metallic = 0.85
	lance.mesh = cyl
	lance.material_override = l_mat
	lance.position = Vector3(0.5, 1.0, -0.4)
	lance.rotation_degrees.x = 45.0
	visual_mesh.add_child(lance)
	weapon_node = lance

func _process_animations(delta: float) -> void:
	if not visual_mesh or is_dying:
		return

	# Hit flash recovery
	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0 and tunic_node and tunic_mat:
			tunic_node.material_override = tunic_mat

	# Attack lunge
	if is_attacking_anim:
		super._process_animations(delta)
		return

	# Galloping Steed Locomotion
	if velocity.length_squared() > 0.1:
		walk_cycle += delta * move_speed * 1.5
		visual_mesh.position.y = abs(sin(walk_cycle * 2.2)) * 0.2
		visual_mesh.rotation.z = -sin(walk_cycle) * 0.09
		visual_mesh.rotation.x = 0.15 + sin(walk_cycle * 2.2) * 0.05
		if weapon_node:
			weapon_node.rotation.x = deg_to_rad(45.0) + sin(walk_cycle * 2.2) * 0.22
	else:
		super._process_animations(delta)
