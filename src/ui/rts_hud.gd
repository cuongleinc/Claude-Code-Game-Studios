class_name RTSHud
extends Control

signal build_requested(building_type: String)
signal train_unit_requested(unit_type: String, building: BuildingBase)
signal age_advance_requested()
signal minimap_clicked(world_pos: Vector3)

# Top Bar Labels
var food_label: Label
var wood_label: Label
var stone_label: Label
var gold_label: Label
var pop_label: Label
var age_button: Button
var notification_label: Label

# Selection Panel
var selection_panel: PanelContainer
var sel_title: Label
var sel_info: Label
var sel_action_box: HBoxContainer

# Build Menu
var build_drawer: PanelContainer

# Victory/Defeat Popup
var popup_panel: PanelContainer
var popup_label: Label

# Notification timer
var notif_timer: float = 0.0

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	build_top_bar()
	build_selection_ui()
	build_build_drawer()
	build_minimap()
	build_notification_ticker()
	build_game_over_popup()

	if GameManager.instance:
		GameManager.instance.resources_changed.connect(_on_resources_changed)
		GameManager.instance.age_advanced.connect(_on_age_advanced)
		GameManager.instance.game_state_changed.connect(_on_game_state_changed)
		GameManager.instance.selection_changed.connect(_on_selection_changed)
		GameManager.instance.notification_posted.connect(show_notification)
		_on_resources_changed(GameManager.instance.resources)
		update_age_button_text()

func build_top_bar() -> void:
	var top_panel = PanelContainer.new()
	top_panel.anchor_right = 1.0
	top_panel.offset_bottom = 60.0

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.13, 0.17, 0.94)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	top_panel.add_theme_stylebox_override("panel", style)
	add_child(top_panel)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 20)
	top_panel.add_child(hbox)

	# Island Lord Pixel Art Avatar
	var avatar_box = HBoxContainer.new()
	avatar_box.add_theme_constant_override("separation", 8)
	var avatar_path = "res://assets/ui/island_lord.png"
	if ResourceLoader.exists(avatar_path):
		var avatar_rect = TextureRect.new()
		avatar_rect.texture = load(avatar_path)
		avatar_rect.custom_minimum_size = Vector2(38, 38)
		avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		avatar_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		avatar_box.add_child(avatar_rect)

	var lord_lbl = Label.new()
	lord_lbl.text = "Lord of the Isle"
	lord_lbl.add_theme_font_size_override("font_size", 14)
	lord_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
	avatar_box.add_child(lord_lbl)
	hbox.add_child(avatar_box)

	# Resource Badges with PixelLab Icons
	food_label = create_icon_badge(hbox, "res://assets/ui/icon_food.png", "200")
	wood_label = create_icon_badge(hbox, "res://assets/ui/icon_wood.png", "300")
	stone_label = create_icon_badge(hbox, "res://assets/ui/icon_stone.png", "150")
	gold_label = create_icon_badge(hbox, "res://assets/ui/icon_gold.png", "100")
	pop_label = create_text_badge(hbox, "👥 3/10")

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Age advancement button
	age_button = Button.new()
	age_button.custom_minimum_size = Vector2(240, 36)
	age_button.pressed.connect(_on_age_button_pressed)
	hbox.add_child(age_button)

	# Speed controls
	var speed_box = HBoxContainer.new()
	var pause_btn = Button.new()
	pause_btn.text = "⏸️"
	pause_btn.pressed.connect(func(): if GameManager.instance: GameManager.instance.set_game_speed(0.0))
	speed_box.add_child(pause_btn)

	var play_btn = Button.new()
	play_btn.text = "▶️ 1x"
	play_btn.pressed.connect(func(): if GameManager.instance: GameManager.instance.set_game_speed(1.0))
	speed_box.add_child(play_btn)

	var fast_btn = Button.new()
	fast_btn.text = "⏩ 2x"
	fast_btn.pressed.connect(func(): if GameManager.instance: GameManager.instance.set_game_speed(2.0))
	speed_box.add_child(fast_btn)
	hbox.add_child(speed_box)

func create_icon_badge(parent: Control, icon_path: String, initial_val: String) -> Label:
	var badge = HBoxContainer.new()
	badge.add_theme_constant_override("separation", 6)

	if ResourceLoader.exists(icon_path):
		var tr = TextureRect.new()
		tr.texture = load(icon_path)
		tr.custom_minimum_size = Vector2(24, 24)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		badge.add_child(tr)

	var lbl = Label.new()
	lbl.text = initial_val
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96))
	badge.add_child(lbl)

	parent.add_child(badge)
	return lbl

func create_text_badge(parent: Control, text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	parent.add_child(lbl)
	return lbl

func build_selection_ui() -> void:
	selection_panel = PanelContainer.new()
	selection_panel.anchor_top = 1.0
	selection_panel.anchor_bottom = 1.0
	selection_panel.offset_left = 220.0
	selection_panel.offset_top = -145.0
	selection_panel.offset_right = 680.0
	selection_panel.offset_bottom = -16.0
	selection_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.2, 0.92)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14.0
	style.content_margin_top = 8.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 8.0
	selection_panel.add_theme_stylebox_override("panel", style)
	add_child(selection_panel)

	var vbox = VBoxContainer.new()
	selection_panel.add_child(vbox)

	sel_title = Label.new()
	sel_title.text = "Selected Entity"
	sel_title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(sel_title)

	sel_info = Label.new()
	sel_info.text = "HP: 100/100"
	sel_info.add_theme_font_size_override("font_size", 13)
	sel_info.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	vbox.add_child(sel_info)

	sel_action_box = HBoxContainer.new()
	sel_action_box.add_theme_constant_override("separation", 8)
	vbox.add_child(sel_action_box)

func build_build_drawer() -> void:
	build_drawer = PanelContainer.new()
	build_drawer.anchor_left = 1.0
	build_drawer.anchor_top = 1.0
	build_drawer.anchor_right = 1.0
	build_drawer.anchor_bottom = 1.0
	build_drawer.offset_left = -460.0
	build_drawer.offset_top = -155.0
	build_drawer.offset_right = -16.0
	build_drawer.offset_bottom = -16.0

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.14, 0.18, 0.94)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12.0
	style.content_margin_top = 8.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 8.0
	build_drawer.add_theme_stylebox_override("panel", style)
	add_child(build_drawer)

	var vbox = VBoxContainer.new()
	build_drawer.add_child(vbox)

	var title = Label.new()
	title.text = "🔨 Construction Menu"
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	add_build_button(grid, "house", "🏠 House\n(50W)")
	add_build_button(grid, "farm", "🌾 Farm\n(60W)")
	add_build_button(grid, "lumber_camp", "🪵 Camp\n(80W)")
	add_build_button(grid, "barracks", "⚔️ Barracks\n(120W, 60S)")
	add_build_button(grid, "harbor", "⚓ Harbor\n(150W, 80S)")
	add_build_button(grid, "guard_tower", "🏹 Tower\n(100W, 80S)")
	add_build_button(grid, "stone_wall", "🧱 Wall\n(25S)")
	add_build_button(grid, "catapult_workshop", "⚙️ Workshop\n(180W, 120S, 60G)")

func add_build_button(parent: Control, type: String, label_text: String) -> void:
	var btn = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(100, 44)
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(func(): emit_signal("build_requested", type))
	parent.add_child(btn)

func build_minimap() -> void:
	var map_panel = PanelContainer.new()
	map_panel.anchor_top = 1.0
	map_panel.anchor_bottom = 1.0
	map_panel.offset_left = 16.0
	map_panel.offset_top = -180.0
	map_panel.offset_right = 196.0
	map_panel.offset_bottom = -16.0

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.25, 0.35, 0.85)
	style.border_color = Color(0.3, 0.6, 0.7)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	map_panel.add_theme_stylebox_override("panel", style)
	add_child(map_panel)

	var label = Label.new()
	label.text = "Archipelago Map"
	label.position = Vector2(8.0, 6.0)
	label.add_theme_font_size_override("font_size", 11)
	map_panel.add_child(label)

func build_notification_ticker() -> void:
	notification_label = Label.new()
	notification_label.anchor_left = 0.5
	notification_label.anchor_right = 0.5
	notification_label.offset_left = -250.0
	notification_label.offset_top = 68.0
	notification_label.offset_right = 250.0
	notification_label.offset_bottom = 98.0
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 15)
	notification_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	notification_label.visible = false
	add_child(notification_label)

func build_game_over_popup() -> void:
	popup_panel = PanelContainer.new()
	popup_panel.anchor_left = 0.5
	popup_panel.anchor_top = 0.5
	popup_panel.anchor_right = 0.5
	popup_panel.anchor_bottom = 0.5
	popup_panel.offset_left = -220.0
	popup_panel.offset_top = -110.0
	popup_panel.offset_right = 220.0
	popup_panel.offset_bottom = 110.0
	popup_panel.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.16, 0.96)
	style.border_color = Color(0.9, 0.75, 0.2)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 20.0
	style.content_margin_top = 20.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 20.0
	popup_panel.add_theme_stylebox_override("panel", style)
	add_child(popup_panel)

	var vbox = VBoxContainer.new()
	popup_panel.add_child(vbox)

	popup_label = Label.new()
	popup_label.text = "VICTORY!"
	popup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(popup_label)

	var restart_btn = Button.new()
	restart_btn.text = "Play Again"
	restart_btn.pressed.connect(func(): get_tree().reload_current_scene())
	vbox.add_child(restart_btn)

func _process(delta: float) -> void:
	if notif_timer > 0.0:
		notif_timer -= delta
		if notif_timer <= 0.0:
			notification_label.visible = false

func show_notification(msg: String) -> void:
	notification_label.text = msg
	notification_label.visible = true
	notif_timer = 4.0

func _on_resources_changed(res: Dictionary) -> void:
	food_label.text = str(res.get("food", 0))
	wood_label.text = str(res.get("wood", 0))
	stone_label.text = str(res.get("stone", 0))
	gold_label.text = str(res.get("gold", 0))
	pop_label.text = "👥 " + str(res.get("population", 0)) + "/" + str(res.get("max_population", 10))
	update_age_button_text()

func update_age_button_text() -> void:
	if not GameManager.instance or not age_button:
		return

	var cur = GameManager.instance.current_age
	var cur_name = GameManager.instance.age_names[cur]

	if cur >= GameManager.Age.MEDIEVAL_AGE:
		age_button.text = "👑 " + cur_name + " (Apex)"
		age_button.disabled = true
	else:
		var next_name = GameManager.instance.age_names[cur + 1]
		var cost = GameManager.instance.get_next_age_cost()
		var cost_str = ""
		for k in cost.keys():
			var letter = k.left(1).to_upper()
			cost_str += str(cost[k]) + letter + " "
		age_button.text = "🏛️ " + cur_name + " -> " + next_name + " (" + cost_str.strip_edges() + ")"
		age_button.disabled = false

func _on_age_advanced(_new_age: String) -> void:
	update_age_button_text()

func _on_age_button_pressed() -> void:
	emit_signal("age_advance_requested")

func _on_game_state_changed(state: String) -> void:
	popup_panel.visible = true
	if state == "victory":
		popup_label.text = "👑 VICTORY!\nArchipelago Conquered!"
		popup_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		popup_label.text = "💀 DEFEAT!\nYour Empire Has Fallen!"
		popup_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))

func _on_selection_changed(entities: Array) -> void:
	for child in sel_action_box.get_children():
		child.queue_free()

	if entities.is_empty():
		selection_panel.visible = false
		return

	selection_panel.visible = true
	var first = entities[0]

	if first is BuildingBase:
		var b: BuildingBase = first
		sel_title.text = b.building_type.capitalize() + " (" + b.team.capitalize() + ")"
		sel_info.text = "HP: " + str(b.current_hp) + "/" + str(b.max_hp)

		if b.team == "player":
			match b.building_type:
				"town_center":
					var train_v = Button.new()
					train_v.text = "Train Villager (50F)"
					train_v.pressed.connect(func(): emit_signal("train_unit_requested", "villager", b))
					sel_action_box.add_child(train_v)

					var train_h = Button.new()
					train_h.text = "Summon Lord (150F, 150G)"
					train_h.pressed.connect(func(): emit_signal("train_unit_requested", "hero_commander", b))
					sel_action_box.add_child(train_h)

				"barracks":
					var train_s = Button.new()
					train_s.text = "Spearman (60F, 30W)"
					train_s.pressed.connect(func(): emit_signal("train_unit_requested", "spearman", b))
					sel_action_box.add_child(train_s)

					var train_a = Button.new()
					train_a.text = "Archer (50F, 50W)"
					train_a.pressed.connect(func(): emit_signal("train_unit_requested", "archer", b))
					sel_action_box.add_child(train_a)

				"harbor":
					var build_s = Button.new()
					build_s.text = "Galley (120W, 40G)"
					build_s.pressed.connect(func(): emit_signal("train_unit_requested", "transport_ship", b))
					sel_action_box.add_child(build_s)

					var build_g = Button.new()
					build_g.text = "War Galleon (220W, 80S, 100G)"
					build_g.pressed.connect(func(): emit_signal("train_unit_requested", "war_galleon", b))
					sel_action_box.add_child(build_g)

				"catapult_workshop":
					var train_c = Button.new()
					train_c.text = "Build Catapult (150W, 100S, 50G)"
					train_c.pressed.connect(func(): emit_signal("train_unit_requested", "catapult", b))
					sel_action_box.add_child(train_c)

	elif first is TransportShip:
		var ship: TransportShip = first
		sel_title.text = "Galley Transport"
		sel_info.text = "Embarked: " + str(ship.embarked_units.size()) + "/" + str(ship.max_capacity) + " | HP: " + str(ship.current_hp)
		var disembark_btn = Button.new()
		disembark_btn.text = "Disembark Troops"
		disembark_btn.pressed.connect(func(): ship.disembark_all(ship.global_position))
		sel_action_box.add_child(disembark_btn)

	elif first is WarGalleon:
		var wship: WarGalleon = first
		sel_title.text = "War Galleon"
		sel_info.text = "HP: " + str(wship.current_hp) + "/" + str(wship.max_hp) + " | Cannon: 35 Dmg"

	elif first is Catapult:
		var cat: Catapult = first
		sel_title.text = "Siege Catapult"
		sel_info.text = "HP: " + str(cat.current_hp) + "/" + str(cat.max_hp) + " | Siege: 45 Dmg (24m Range)"

	elif first is HeroCommander:
		var hero: HeroCommander = first
		sel_title.text = "Island Lord (Hero Commander)"
		sel_info.text = "HP: " + str(hero.current_hp) + "/" + str(hero.max_hp) + " | Inspiring Aura (12m)"

	elif first is UnitBase:
		var u: UnitBase = first
		sel_title.text = u.unit_name + " (" + u.team.capitalize() + ")"
		sel_info.text = "HP: " + str(u.current_hp) + "/" + str(u.max_hp) + " | Dmg: " + str(u.attack_damage)
