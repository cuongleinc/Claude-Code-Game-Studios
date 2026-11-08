class_name MilitaryUnit
extends UnitBase

const SlashEffectScript = preload("res://src/combat/slash_effect.gd")
const ProjectileScript = preload("res://src/units/projectile.gd")

@export var military_type: String = "spearman"

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
		"barbarian", "clan_berserker":
			unit_name = "Clan Berserker"
			team = "enemy"
			max_hp = 110
			attack_damage = 18
			attack_range = 1.8
			attack_cooldown = 1.1
			move_speed = 6.0
		"corsair_raider":
			unit_name = "Corsair Raider"
			team = "enemy"
			max_hp = 125
			attack_damage = 20
			attack_range = 1.8
			attack_cooldown = 0.95
			move_speed = 6.6
		"dread_captain":
			unit_name = "Dread Captain Flint"
			team = "enemy"
			max_hp = 650
			attack_damage = 40
			attack_range = 2.8
			attack_cooldown = 1.4
			move_speed = 6.0
		"clan_chieftain":
			unit_name = "Chieftain Gorgar"
			team = "enemy"
			max_hp = 750
			attack_damage = 48
			attack_range = 2.6
			attack_cooldown = 1.6
			move_speed = 5.2

	super._ready()
	build_weapon_visual()
	attach_pixel_art_billboard()

func attach_pixel_art_billboard() -> void:
	var sprite_map = {
		"barbarian": "res://assets/enemies/clan_berserker.png",
		"clan_berserker": "res://assets/enemies/clan_berserker.png",
		"clan_chieftain": "res://assets/enemies/clan_chieftain.png",
		"corsair_raider": "res://assets/enemies/corsair_raider.png",
		"dread_captain": "res://assets/enemies/dread_captain.png"
	}

	if sprite_map.has(military_type):
		var path = sprite_map[military_type]
		if ResourceLoader.exists(path):
			var tex = load(path)
			var sprite = Sprite3D.new()
			sprite.texture = tex
			var is_boss = (military_type in ["dread_captain", "clan_chieftain"])
			sprite.pixel_size = 0.026 if is_boss else 0.02
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			sprite.position = Vector3(0.0, 1.4 if is_boss else 1.1, 0.0)
			visual_mesh.add_child(sprite)

			if is_boss:
				# Imposing boss aura ring on ground
				var ring = MeshInstance3D.new()
				var torus = TorusMesh.new()
				torus.inner_radius = 1.6
				torus.outer_radius = 1.85
				ring.mesh = torus
				var r_mat = StandardMaterial3D.new()
				r_mat.albedo_color = Color(0.9, 0.15, 0.15, 0.5)
				r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				ring.material_override = r_mat
				ring.position = Vector3(0.0, 0.06, 0.0)
				add_child(ring)

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
			weapon_node = spear
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
			weapon_node = bow
		"barbarian", "clan_berserker":
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
			weapon_node = club
		"corsair_raider":
			var blades_root = Node3D.new()
			blades_root.name = "BladesRoot"
			visual_mesh.add_child(blades_root)
			weapon_node = blades_root
			for side in [-0.4, 0.4]:
				var blade = MeshInstance3D.new()
				var box = BoxMesh.new()
				box.size = Vector3(0.06, 0.9, 0.12)
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.85, 0.85, 0.9)
				mat.metallic = 0.8
				blade.mesh = box
				blade.material_override = mat
				blade.position = Vector3(side, 0.8, -0.2)
				blade.rotation_degrees.x = 40.0
				blades_root.add_child(blade)
		"dread_captain":
			var sword = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(0.08, 1.3, 0.15)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.9, 0.8, 0.2)
			mat.metallic = 0.85
			sword.mesh = box
			sword.material_override = mat
			sword.position = Vector3(0.45, 0.9, -0.25)
			sword.rotation_degrees.x = 35.0
			visual_mesh.add_child(sword)
			weapon_node = sword
		"clan_chieftain":
			var greataxe = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(0.12, 1.5, 0.28)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.65, 0.25, 0.15)
			mat.metallic = 0.7
			greataxe.mesh = box
			greataxe.material_override = mat
			greataxe.position = Vector3(0.5, 0.95, -0.25)
			greataxe.rotation_degrees.x = 40.0
			visual_mesh.add_child(greataxe)
			weapon_node = greataxe

func perform_attack() -> void:
	if not is_instance_valid(target_entity):
		return

	trigger_attack_anim()
	look_at_safe(target_entity.global_position)

	if military_type == "archer":
		if is_inside_tree() and get_parent():
			var proj = ProjectileScript.new()
			get_parent().add_child(proj)
			proj.setup(global_position + Vector3(0.0, 1.0, 0.0), target_entity, attack_damage, false, self)
	else:
		# Melee weapon strike
		if is_inside_tree() and get_parent():
			var slash = SlashEffectScript.new()
			get_parent().add_child(slash)
			var strike_pos = (global_position + target_entity.global_position) * 0.5 + Vector3(0.0, 0.8, 0.0)
			var attack_dir = (target_entity.global_position - global_position).normalized()
			var slash_color = Color(0.3, 0.85, 1.0) if team == "player" else Color(1.0, 0.3, 0.2)
			slash.setup(strike_pos, attack_dir, slash_color)

		if target_entity.has_method("take_damage"):
			target_entity.take_damage(attack_damage, self)
