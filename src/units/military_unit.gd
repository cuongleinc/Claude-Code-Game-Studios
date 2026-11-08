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
	build_military_equipment()

func build_military_equipment() -> void:
	var steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.85, 0.88, 0.92)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.2

	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.82, 0.15)
	gold_mat.metallic = 0.9
	gold_mat.roughness = 0.15

	var dark_iron_mat = StandardMaterial3D.new()
	dark_iron_mat.albedo_color = Color(0.28, 0.30, 0.32)
	dark_iron_mat.metallic = 0.75
	dark_iron_mat.roughness = 0.3

	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.50, 0.32, 0.16)
	wood_mat.roughness = 0.75

	var is_boss = (military_type in ["dread_captain", "clan_chieftain"])
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

	match military_type:
		"spearman":
			# 1. Hoplite Crest Helmet
			if head_node:
				var helm = MeshInstance3D.new()
				var h_mesh = CylinderMesh.new()
				h_mesh.top_radius = 0.135
				h_mesh.bottom_radius = 0.135
				h_mesh.height = 0.18
				helm.mesh = h_mesh
				helm.material_override = steel_mat
				helm.position = Vector3(0.0, 0.06, 0.0)
				head_node.add_child(helm)

				# Crest brush on top
				var crest = MeshInstance3D.new()
				var c_box = BoxMesh.new()
				c_box.size = Vector3(0.04, 0.14, 0.28)
				var c_mat = StandardMaterial3D.new()
				c_mat.albedo_color = Color(0.18, 0.45, 0.88) if team == "player" else Color(0.85, 0.2, 0.2)
				crest.mesh = c_box
				crest.material_override = c_mat
				crest.position = Vector3(0.0, 0.19, 0.0)
				head_node.add_child(crest)

			# 2. Long Phalanx Spear (in right hand)
			var spear_node = Node3D.new()
			spear_node.name = "PhalanxSpear"
			var shaft = MeshInstance3D.new()
			var s_cyl = CylinderMesh.new()
			s_cyl.top_radius = 0.025
			s_cyl.bottom_radius = 0.025
			s_cyl.height = 2.1
			shaft.mesh = s_cyl
			shaft.material_override = wood_mat
			shaft.position = Vector3(0.0, 0.4, 0.0)
			spear_node.add_child(shaft)

			var tip = MeshInstance3D.new()
			var tip_cone = CylinderMesh.new()
			tip_cone.top_radius = 0.0
			tip_cone.bottom_radius = 0.06
			tip_cone.height = 0.25
			tip.mesh = tip_cone
			tip.material_override = steel_mat
			tip.position = Vector3(0.0, 1.55, 0.0)
			spear_node.add_child(tip)

			spear_node.position = Vector3(0.0, -0.05, 0.08)
			spear_node.rotation_degrees = Vector3(30.0, 0.0, 0.0)
			if right_hand_node:
				right_hand_node.add_child(spear_node)
			else:
				visual_mesh.add_child(spear_node)
			weapon_node = spear_node

			# 3. Round Hoplite Shield (on left arm)
			var shield = MeshInstance3D.new()
			var sh_cyl = CylinderMesh.new()
			sh_cyl.top_radius = 0.24
			sh_cyl.bottom_radius = 0.24
			sh_cyl.height = 0.04
			var sh_mat = StandardMaterial3D.new()
			sh_mat.albedo_color = Color(0.18, 0.45, 0.88) if team == "player" else Color(0.85, 0.2, 0.2)
			shield.mesh = sh_cyl
			shield.material_override = sh_mat
			shield.position = Vector3(-0.08, -0.12, 0.08)
			shield.rotation_degrees = Vector3(0.0, 0.0, 90.0)
			if left_arm_pivot:
				left_arm_pivot.add_child(shield)

		"archer":
			# 1. Woodland Ranger Cap with Feather
			if head_node:
				var cap = MeshInstance3D.new()
				var c_box = BoxMesh.new()
				c_box.size = Vector3(0.26, 0.12, 0.28)
				var c_mat = StandardMaterial3D.new()
				c_mat.albedo_color = Color(0.20, 0.50, 0.22)
				cap.mesh = c_box
				cap.material_override = c_mat
				cap.position = Vector3(0.0, 0.12, 0.0)
				head_node.add_child(cap)

				var feather = MeshInstance3D.new()
				var f_box = BoxMesh.new()
				f_box.size = Vector3(0.02, 0.18, 0.06)
				var f_mat = StandardMaterial3D.new()
				f_mat.albedo_color = Color(0.9, 0.15, 0.15)
				feather.mesh = f_box
				feather.material_override = f_mat
				feather.position = Vector3(-0.14, 0.20, -0.06)
				feather.rotation_degrees.z = -20.0
				head_node.add_child(feather)

			# 2. Recurve Longbow (in left hand)
			var bow_node = Node3D.new()
			bow_node.name = "Longbow"
			var bow_arch = MeshInstance3D.new()
			var b_torus = TorusMesh.new()
			b_torus.inner_radius = 0.32
			b_torus.outer_radius = 0.38
			bow_arch.mesh = b_torus
			bow_arch.material_override = wood_mat
			bow_node.add_child(bow_arch)

			# Bowstring
			var string_mesh = MeshInstance3D.new()
			var s_cyl = CylinderMesh.new()
			s_cyl.top_radius = 0.01
			s_cyl.bottom_radius = 0.01
			s_cyl.height = 0.65
			var s_mat = StandardMaterial3D.new()
			s_mat.albedo_color = Color(0.9, 0.9, 0.9)
			string_mesh.mesh = s_cyl
			string_mesh.material_override = s_mat
			string_mesh.position = Vector3(0.0, 0.0, -0.32)
			bow_node.add_child(string_mesh)

			bow_node.position = Vector3(0.0, -0.05, 0.08)
			bow_node.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			if left_hand_node:
				left_hand_node.add_child(bow_node)
			else:
				visual_mesh.add_child(bow_node)
			weapon_node = bow_node

			# 3. Arrow Quiver on Back
			if torso_node:
				var quiver = MeshInstance3D.new()
				var q_cyl = CylinderMesh.new()
				q_cyl.top_radius = 0.06
				q_cyl.bottom_radius = 0.05
				q_cyl.height = 0.36
				var q_mat = StandardMaterial3D.new()
				q_mat.albedo_color = Color(0.42, 0.28, 0.15)
				quiver.mesh = q_cyl
				quiver.material_override = q_mat
				quiver.position = Vector3(0.08, 0.05, -0.15)
				quiver.rotation_degrees.z = -15.0
				torso_node.add_child(quiver)

		"barbarian", "clan_berserker":
			# 1. Horned Viking Helm
			if head_node:
				var helm = MeshInstance3D.new()
				var h_mesh = CylinderMesh.new()
				h_mesh.top_radius = 0.135
				h_mesh.bottom_radius = 0.135
				h_mesh.height = 0.18
				helm.mesh = h_mesh
				helm.material_override = dark_iron_mat
				helm.position = Vector3(0.0, 0.06, 0.0)
				head_node.add_child(helm)

				# Ivory Bull Horns
				var horn_mat = StandardMaterial3D.new()
				horn_mat.albedo_color = Color(0.95, 0.92, 0.85)
				for side in [-1, 1]:
					var horn = MeshInstance3D.new()
					var hn_cone = CylinderMesh.new()
					hn_cone.top_radius = 0.015
					hn_cone.bottom_radius = 0.045
					hn_cone.height = 0.22
					horn.mesh = hn_cone
					horn.material_override = horn_mat
					horn.position = Vector3(side * 0.15, 0.16, 0.0)
					horn.rotation_degrees = Vector3(0.0, 0.0, side * 35.0)
					head_node.add_child(horn)

			# 2. Heavy Double-Headed Battleaxe
			var axe_node = Node3D.new()
			axe_node.name = "BerserkerAxe"
			var haft = MeshInstance3D.new()
			var h_cyl = CylinderMesh.new()
			h_cyl.top_radius = 0.025
			h_cyl.bottom_radius = 0.025
			h_cyl.height = 0.9
			haft.mesh = h_cyl
			haft.material_override = wood_mat
			axe_node.add_child(haft)

			# Twin axe blades
			for b_side in [-1, 1]:
				var b = MeshInstance3D.new()
				var b_box = BoxMesh.new()
				b_box.size = Vector3(0.03, 0.22, 0.18)
				b.mesh = b_box
				b.material_override = steel_mat
				b.position = Vector3(0.0, 0.32, b_side * 0.10)
				axe_node.add_child(b)

			axe_node.position = Vector3(0.0, -0.06, 0.10)
			axe_node.rotation_degrees = Vector3(35.0, 0.0, 0.0)
			if right_hand_node:
				right_hand_node.add_child(axe_node)
			else:
				visual_mesh.add_child(axe_node)
			weapon_node = axe_node

		"corsair_raider":
			# 1. Pirate Tricorn Hat
			if head_node:
				var hat = MeshInstance3D.new()
				var tricorn = BoxMesh.new()
				tricorn.size = Vector3(0.34, 0.10, 0.32)
				var th_mat = StandardMaterial3D.new()
				th_mat.albedo_color = Color(0.12, 0.12, 0.14)
				hat.mesh = tricorn
				hat.material_override = th_mat
				hat.position = Vector3(0.0, 0.15, 0.0)
				head_node.add_child(hat)

				# Skull Stud Badge on hat front
				var skull_stud = MeshInstance3D.new()
				var sk_cyl = CylinderMesh.new()
				sk_cyl.top_radius = 0.035
				sk_cyl.bottom_radius = 0.035
				sk_cyl.height = 0.03
				var sk_mat = StandardMaterial3D.new()
				sk_mat.albedo_color = Color(0.95, 0.95, 0.95)
				skull_stud.mesh = sk_cyl
				skull_stud.material_override = sk_mat
				skull_stud.position = Vector3(0.0, 0.15, 0.16)
				skull_stud.rotation_degrees.x = 90.0
				head_node.add_child(skull_stud)

			# 2. Polished Pirate Cutlass
			var cutlass_node = Node3D.new()
			cutlass_node.name = "PirateCutlass"
			var c_blade = MeshInstance3D.new()
			var c_box = BoxMesh.new()
			c_box.size = Vector3(0.035, 0.65, 0.10)
			c_blade.mesh = c_box
			c_blade.material_override = steel_mat
			c_blade.position = Vector3(0.0, 0.24, 0.0)
			cutlass_node.add_child(c_blade)

			# Brass knuckle-guard
			var guard = MeshInstance3D.new()
			var g_torus = TorusMesh.new()
			g_torus.inner_radius = 0.05
			g_torus.outer_radius = 0.08
			guard.mesh = g_torus
			guard.material_override = gold_mat
			guard.position = Vector3(0.0, -0.06, 0.0)
			guard.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			cutlass_node.add_child(guard)

			cutlass_node.position = Vector3(0.0, -0.05, 0.08)
			cutlass_node.rotation_degrees = Vector3(35.0, 0.0, 0.0)
			if right_hand_node:
				right_hand_node.add_child(cutlass_node)
			else:
				visual_mesh.add_child(cutlass_node)
			weapon_node = cutlass_node

		"dread_captain":
			# 1. Admiral Bicorn Hat with Crimson Plume
			if head_node:
				var b_hat = MeshInstance3D.new()
				var bh_box = BoxMesh.new()
				bh_box.size = Vector3(0.40, 0.14, 0.26)
				var bh_mat = StandardMaterial3D.new()
				bh_mat.albedo_color = Color(0.12, 0.12, 0.15)
				b_hat.mesh = bh_box
				b_hat.material_override = bh_mat
				b_hat.position = Vector3(0.0, 0.16, 0.0)
				head_node.add_child(b_hat)

				# Crimson Captain Plume
				var plume = MeshInstance3D.new()
				var p_box = BoxMesh.new()
				p_box.size = Vector3(0.04, 0.22, 0.12)
				var p_mat = StandardMaterial3D.new()
				p_mat.albedo_color = Color(0.9, 0.15, 0.15)
				plume.mesh = p_box
				plume.material_override = p_mat
				plume.position = Vector3(0.0, 0.26, 0.0)
				head_node.add_child(plume)

			# 2. Golden Epaulets on Torso Shoulders
			if torso_node:
				for ep_x in [-0.17, 0.17]:
					var ep = MeshInstance3D.new()
					var ep_box = BoxMesh.new()
					ep_box.size = Vector3(0.08, 0.05, 0.14)
					ep.mesh = ep_box
					ep.material_override = gold_mat
					ep.position = Vector3(ep_x, 0.20, 0.0)
					torso_node.add_child(ep)

			# 3. Dread Pirate Cutlass
			var captain_blade = MeshInstance3D.new()
			var cb_box = BoxMesh.new()
			cb_box.size = Vector3(0.05, 0.85, 0.12)
			captain_blade.mesh = cb_box
			captain_blade.material_override = gold_mat
			captain_blade.position = Vector3(0.0, 0.28, 0.0)
			var cb_node = Node3D.new()
			cb_node.name = "CaptainBlade"
			cb_node.add_child(captain_blade)
			cb_node.position = Vector3(0.0, -0.06, 0.08)
			cb_node.rotation_degrees = Vector3(35.0, 0.0, 0.0)
			if right_hand_node:
				right_hand_node.add_child(cb_node)
			else:
				visual_mesh.add_child(cb_node)
			weapon_node = cb_node

		"clan_chieftain":
			# 1. Golden Horned War Helm
			if head_node:
				var helm = MeshInstance3D.new()
				var h_mesh = CylinderMesh.new()
				h_mesh.top_radius = 0.145
				h_mesh.bottom_radius = 0.145
				h_mesh.height = 0.20
				helm.mesh = h_mesh
				helm.material_override = gold_mat
				helm.position = Vector3(0.0, 0.06, 0.0)
				head_node.add_child(helm)

				for side in [-1, 1]:
					var horn = MeshInstance3D.new()
					var hn_cone = CylinderMesh.new()
					hn_cone.top_radius = 0.02
					hn_cone.bottom_radius = 0.06
					hn_cone.height = 0.28
					horn.mesh = hn_cone
					horn.material_override = steel_mat
					horn.position = Vector3(side * 0.18, 0.18, 0.0)
					horn.rotation_degrees = Vector3(0.0, 0.0, side * 35.0)
					head_node.add_child(horn)

			# 2. Colossal War Greataxe
			var axe_node = Node3D.new()
			axe_node.name = "ChiefGreataxe"
			var haft = MeshInstance3D.new()
			var h_cyl = CylinderMesh.new()
			h_cyl.top_radius = 0.03
			h_cyl.bottom_radius = 0.03
			h_cyl.height = 1.2
			haft.mesh = h_cyl
			haft.material_override = dark_iron_mat
			axe_node.add_child(haft)

			for b_side in [-1, 1]:
				var b = MeshInstance3D.new()
				var b_box = BoxMesh.new()
				b_box.size = Vector3(0.04, 0.32, 0.24)
				b.mesh = b_box
				b.material_override = gold_mat
				b.position = Vector3(0.0, 0.44, b_side * 0.14)
				axe_node.add_child(b)

			axe_node.position = Vector3(0.0, -0.06, 0.10)
			axe_node.rotation_degrees = Vector3(35.0, 0.0, 0.0)
			if right_hand_node:
				right_hand_node.add_child(axe_node)
			else:
				visual_mesh.add_child(axe_node)
			weapon_node = axe_node

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
