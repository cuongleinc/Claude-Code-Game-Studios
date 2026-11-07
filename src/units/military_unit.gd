class_name MilitaryUnit
extends UnitBase

@export var military_type: String = "spearman" # "spearman", "archer", "barbarian"

func _ready() -> void:
	match military_type:
		"spearman":
			unit_name = "Spearman"
			max_hp = 130
			attack_damage = 18
			attack_range = 2.0
			attack_cooldown = 1.1
			move_speed = 6.0
		"archer":
			unit_name = "Archer"
			max_hp = 80
			attack_damage = 14
			attack_range = 14.0
			attack_cooldown = 1.6
			move_speed = 6.2
		"barbarian":
			unit_name = "Barbarian"
			team = "enemy"
			max_hp = 110
			attack_damage = 15
			attack_range = 1.8
			attack_cooldown = 1.2
			move_speed = 5.8

	super._ready()
	build_weapon_visual()

func build_weapon_visual() -> void:
	match military_type:
		"spearman":
			var spear = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.04
			cyl.bottom_radius = 0.04
			cyl.height = 2.0
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.7, 0.5, 0.3)
			spear.mesh = cyl
			spear.material_override = mat
			spear.position = Vector3(0.4, 0.9, -0.2)
			spear.rotation_degrees.x = 25.0
			visual_mesh.add_child(spear)
		"archer":
			var bow = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = 0.35
			torus.outer_radius = 0.42
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.5, 0.3, 0.15)
			bow.mesh = torus
			bow.material_override = mat
			bow.position = Vector3(0.35, 0.8, -0.1)
			bow.rotation_degrees.y = 90.0
			visual_mesh.add_child(bow)
		"barbarian":
			var club = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.16
			cyl.bottom_radius = 0.08
			cyl.height = 1.1
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.35, 0.22, 0.15)
			club.mesh = cyl
			club.material_override = mat
			club.position = Vector3(0.4, 0.8, -0.2)
			club.rotation_degrees.x = 45.0
			visual_mesh.add_child(club)

func perform_attack() -> void:
	if not is_instance_valid(target_entity):
		return

	if military_type == "archer":
		# Spawn arrow projectile
		var proj = Projectile.new()
		proj.setup(global_position + Vector3(0.0, 1.0, 0.0), target_entity, attack_damage)
		get_parent().add_child(proj)
	else:
		# Melee attack
		if target_entity.has_method("take_damage"):
			target_entity.take_damage(attack_damage)
