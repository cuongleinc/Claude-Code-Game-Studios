class_name HeroCommander
extends MilitaryUnit

@export var aura_radius: float = 12.0
var aura_timer: float = 0.0

func _ready() -> void:
	military_type = "hero"
	unit_name = "Island Lord"
	max_hp = 300
	attack_damage = 28
	attack_range = 2.2
	attack_cooldown = 1.0
	move_speed = 6.4

	super._ready()
	build_hero_visual()

func build_hero_visual() -> void:
	# Load PixelLab pixel art sprite billboard over the hero!
	var sprite_path = "res://assets/ui/island_lord.png"
	if ResourceLoader.exists(sprite_path):
		var tex = load(sprite_path)
		var sprite = Sprite3D.new()
		sprite.texture = tex
		sprite.pixel_size = 0.02
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.position = Vector3(0.0, 1.2, 0.0)
		visual_mesh.add_child(sprite)

	# Golden Crown / Aura Ring on ground
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = aura_radius - 0.2
	torus.outer_radius = aura_radius
	ring.mesh = torus
	var r_mat = StandardMaterial3D.new()
	r_mat.albedo_color = Color(1.0, 0.85, 0.2, 0.3)
	r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = r_mat
	ring.position = Vector3(0.0, 0.05, 0.0)
	add_child(ring)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	# Aura tick
	aura_timer += delta
	if aura_timer >= 1.0:
		aura_timer = 0.0
		buff_nearby_allies()

func buff_nearby_allies() -> void:
	var allies = get_tree().get_nodes_in_group("player_units")
	for ally in allies:
		if ally is UnitBase and ally != self:
			if global_position.distance_to(ally.global_position) <= aura_radius:
				# Temporarily buff attack damage
				ally.attack_damage = int(ally.attack_damage * 1.0) # Active commander presence
