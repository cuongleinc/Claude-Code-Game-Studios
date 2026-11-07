class_name RTSHud
extends Control

signal build_requested(building_type: String)
signal train_unit_requested(unit_type: String, building: BuildingBase)
signal age_advance_requested()
signal minimap_clicked(world_pos: Vector3)

# Top Bar Elements
var lord_avatar_rect: TextureRect
var empire_name_lbl: Label
var era_badge_lbl: Label
var food_label: Label
var wood_label: Label
var stone_label: Label
var gold_label: Label
var pop_label: Label
var age_button: Button

# Bottom Dock Elements
var minimap_radar: MinimapRadar
var dossier_panel: PanelContainer
var dossier_avatar: TextureRect
var dossier_name: Label
var dossier_hp_bar: ProgressBar
var dossier_hp_text: Label
var dossier_stats: Label
var dossier_actions_box: HBoxContainer

# Command & Build Panel
var command_panel: PanelContainer
var command_title: Label
var command_grid: GridContainer

# Tooltip & Notification
var tooltip_panel: PanelContainer
var tooltip_title: Label
var tooltip_desc: Label
var tooltip_cost: Label
var notif_banner: PanelContainer
var notif_label: Label
var notif_timer: float = 0.0

# Game Over Modal
var game_over_modal: PanelContainer
var game_over_title: Label
var game_over_sub: Label

# Cached building metadata
var building_catalog = {
	"house": {"name": "Cottage", "cost": "50W", "icon": "res://assets/ui/icon_house.png", "desc": "Increases population cap by 5."},
	"farm": {"name": "Farm", "cost": "60W", "icon": "res://assets/ui/icon_farm.png", "desc": "Generates continuous passive food supply."},
	"lumber_camp": {"name": "Lumber Camp", "cost": "80W", "icon": "res://assets/ui/icon_lumber_camp.png", "desc": "Harvest drop-off for nearby forests."},
	"barracks": {"name": "Barracks", "cost": "120W, 60S", "icon": "res://assets/ui/icon_barracks.png", "desc": "Trains Spearmen, Archers, and Royal Knights."},
	"guard_tower": {"name": "Guard Tower", "cost": "100W, 80S", "icon": "res://assets/ui/icon_guard_tower.png", "desc": "Shoots defensive arrows at enemy raiders (18m)."},
	"stone_wall": {"name": "Stone Wall", "cost": "25S", "icon": "res://assets/ui/icon_stone_wall.png", "desc": "Heavy fortifications to block landing parties."},
	"harbor": {"name": "Harbor", "cost": "150W, 80S", "icon": "res://assets/ui/icon_harbor.png", "desc": "Constructs Galley Transports and War Galleons."},
	"catapult_workshop": {"name": "Workshop", "cost": "180W, 120S, 60G", "icon": "res://assets/ui/icon_catapult_workshop.png", "desc": "Constructs heavy siege Catapults."}
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	build_top_ribbon()
	build_bottom_dock()
	build_tooltip_ui()
	build_notification_banner()
	build_game_over_modal()

	if GameManager.instance:
		GameManager.instance.resources_changed.connect(_on_resources_changed)
		GameManager.instance.age_advanced.connect(_on_age_advanced)
		GameManager.instance.game_state_changed.connect(_on_game_state_changed)
		GameManager.instance.selection_changed.connect(_on_selection_changed)
		GameManager.instance.notification_posted.connect(show_notification)
		_on_resources_changed(GameManager.instance.resources)
		update_age_advancement_state()

# ─────────────────────────────────────────────────────────────────────────────
# 1. TOP EMPIRE RIBBON
# ─────────────────────────────────────────────────────────────────────────────
func build_top_ribbon() -> void:
	var top_bar = PanelContainer.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 52)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.12, 0.16, 0.96)
	style.border_color = Color(0.78, 0.65, 0.25)
	style.border_width_bottom = 2
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	top_bar.add_theme_stylebox_override("panel", style)
	add_child(top_bar)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 16)
	top_bar.add_child(hbox)

	# Faction Crest & Name
	var crest_box = HBoxContainer.new()
	crest_box.add_theme_constant_override("separation", 8)

	var lord_path = "res://assets/ui/island_lord.png"
	if ResourceLoader.exists(lord_path):
		var avatar_panel = PanelContainer.new()
		var a_style = StyleBoxFlat.new()
		a_style.bg_color = Color(0.18, 0.15, 0.1, 1.0)
		a_style.border_color = Color(0.85, 0.75, 0.3)
		a_style.border_width_left = 1
		a_style.border_width_right = 1
		a_style.border_width_top = 1
		a_style.border_width_bottom = 1
		a_style.corner_radius_top_left = 4
		a_style.corner_radius_top_right = 4
		a_style.corner_radius_bottom_left = 4
		a_style.corner_radius_bottom_right = 4
		avatar_panel.add_theme_stylebox_override("panel", a_style)

		lord_avatar_rect = TextureRect.new()
		lord_avatar_rect.texture = load(lord_path)
		lord_avatar_rect.custom_minimum_size = Vector2(34, 34)
		lord_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lord_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lord_avatar_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		avatar_panel.add_child(lord_avatar_rect)
		crest_box.add_child(avatar_panel)

	var title_vbox = VBoxContainer.new()
	title_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	empire_name_lbl = Label.new()
	empire_name_lbl.text = "ISLE OF HOPE"
	empire_name_lbl.add_theme_font_size_override("font_size", 13)
	empire_name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	title_vbox.add_child(empire_name_lbl)

	era_badge_lbl = Label.new()
	era_badge_lbl.text = "🏛️ Stone Age (Era I)"
	era_badge_lbl.add_theme_font_size_override("font_size", 10)
	era_badge_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 0.95))
	title_vbox.add_child(era_badge_lbl)
	crest_box.add_child(title_vbox)
	hbox.add_child(crest_box)

	# Divider
	hbox.add_child(create_v_separator())

	# Resource Tablets with PixelLab Icons
	food_label = create_resource_pill(hbox, "res://assets/ui/icon_food.png", "200")
	wood_label = create_resource_pill(hbox, "res://assets/ui/icon_wood.png", "300")
	stone_label = create_resource_pill(hbox, "res://assets/ui/icon_stone.png", "150")
	gold_label = create_resource_pill(hbox, "res://assets/ui/icon_gold.png", "100")
	pop_label = create_text_pill(hbox, "👥 3 / 10")

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Age Advancement Button
	age_button = Button.new()
	age_button.custom_minimum_size = Vector2(230, 36)
	age_button.add_theme_font_size_override("font_size", 12)
	var ab_style = StyleBoxFlat.new()
	ab_style.bg_color = Color(0.2, 0.16, 0.08, 0.95)
	ab_style.border_color = Color(0.9, 0.75, 0.25)
	ab_style.border_width_left = 2
	ab_style.border_width_top = 2
	ab_style.border_width_right = 2
	ab_style.border_width_bottom = 2
	ab_style.corner_radius_top_left = 6
	ab_style.corner_radius_top_right = 6
	ab_style.corner_radius_bottom_left = 6
	ab_style.corner_radius_bottom_right = 6
	age_button.add_theme_stylebox_override("normal", ab_style)
	age_button.pressed.connect(_on_age_button_pressed)
	hbox.add_child(age_button)

	# Speed controls
	var speed_box = HBoxContainer.new()
	speed_box.add_theme_constant_override("separation", 4)
	add_speed_button(speed_box, "⏸", 0.0)
	add_speed_button(speed_box, "▶ 1x", 1.0)
	add_speed_button(speed_box, "⏩ 2x", 2.0)
	hbox.add_child(speed_box)

func create_resource_pill(parent: Control, icon_path: String, val: String) -> Label:
	var pill = PanelContainer.new()
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.12, 0.16, 0.22, 0.85)
	p_style.border_color = Color(0.25, 0.35, 0.45)
	p_style.border_width_left = 1
	p_style.border_width_right = 1
	p_style.border_width_top = 1
	p_style.border_width_bottom = 1
	p_style.corner_radius_top_left = 12
	p_style.corner_radius_top_right = 12
	p_style.corner_radius_bottom_left = 12
	p_style.corner_radius_bottom_right = 12
	p_style.content_margin_left = 8.0
	p_style.content_margin_right = 10.0
	p_style.content_margin_top = 3.0
	p_style.content_margin_bottom = 3.0
	pill.add_theme_stylebox_override("panel", p_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	pill.add_child(hbox)

	if ResourceLoader.exists(icon_path):
		var tr = TextureRect.new()
		tr.texture = load(icon_path)
		tr.custom_minimum_size = Vector2(20, 20)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hbox.add_child(tr)

	var lbl = Label.new()
	lbl.text = val
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96))
	hbox.add_child(lbl)

	parent.add_child(pill)
	return lbl

func create_text_pill(parent: Control, text: String) -> Label:
	var pill = PanelContainer.new()
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.12, 0.16, 0.22, 0.85)
	p_style.border_color = Color(0.25, 0.35, 0.45)
	p_style.border_width_left = 1
	p_style.border_width_right = 1
	p_style.border_width_top = 1
	p_style.border_width_bottom = 1
	p_style.corner_radius_top_left = 12
	p_style.corner_radius_top_right = 12
	p_style.corner_radius_bottom_left = 12
	p_style.corner_radius_bottom_right = 12
	p_style.content_margin_left = 10.0
	p_style.content_margin_right = 10.0
	p_style.content_margin_top = 3.0
	p_style.content_margin_bottom = 3.0
	pill.add_theme_stylebox_override("panel", p_style)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	pill.add_child(lbl)

	parent.add_child(pill)
	return lbl

func create_v_separator() -> Control:
	var sep = VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 24)
	return sep

func add_speed_button(parent: Control, txt: String, speed: float) -> void:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(40, 30)
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(func(): if GameManager.instance: GameManager.instance.set_game_speed(speed))
	parent.add_child(btn)

# ─────────────────────────────────────────────────────────────────────────────
# 2. BOTTOM RTS COMMAND DOCK
# ─────────────────────────────────────────────────────────────────────────────
func build_bottom_dock() -> void:
	var dock_container = PanelContainer.new()
	dock_container.anchor_left = 0.0
	dock_container.anchor_right = 1.0
	dock_container.anchor_top = 1.0
	dock_container.anchor_bottom = 1.0
	dock_container.offset_top = -160.0
	dock_container.offset_bottom = 0.0
	dock_container.offset_left = 0.0
	dock_container.offset_right = 0.0
	dock_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dock_container.custom_minimum_size = Vector2(0, 160)

	var dock_style = StyleBoxFlat.new()
	dock_style.bg_color = Color(0.08, 0.11, 0.15, 0.96)
	dock_style.border_color = Color(0.65, 0.52, 0.22)
	dock_style.border_width_top = 2
	dock_style.content_margin_left = 12.0
	dock_style.content_margin_right = 12.0
	dock_style.content_margin_top = 8.0
	dock_style.content_margin_bottom = 8.0
	dock_container.add_theme_stylebox_override("panel", dock_style)
	add_child(dock_container)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 12)
	dock_container.add_child(hbox)

	# --- Module 1: Minimap Radar (Left) ---
	var minimap_box = PanelContainer.new()
	minimap_box.custom_minimum_size = Vector2(165, 144)
	var m_style = StyleBoxFlat.new()
	m_style.bg_color = Color(0.05, 0.08, 0.12, 1.0)
	m_style.border_color = Color(0.45, 0.4, 0.25)
	m_style.border_width_left = 1
	m_style.border_width_right = 1
	m_style.border_width_top = 1
	m_style.border_width_bottom = 1
	m_style.corner_radius_top_left = 6
	m_style.corner_radius_top_right = 6
	m_style.corner_radius_bottom_left = 6
	m_style.corner_radius_bottom_right = 6
	minimap_box.add_theme_stylebox_override("panel", m_style)

	minimap_radar = MinimapRadar.new()
	minimap_radar.map_position_clicked.connect(_on_minimap_clicked)
	minimap_box.add_child(minimap_radar)
	hbox.add_child(minimap_box)

	# --- Module 2: Entity Dossier (Center) ---
	dossier_panel = PanelContainer.new()
	dossier_panel.custom_minimum_size = Vector2(360, 144)
	dossier_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var d_style = StyleBoxFlat.new()
	d_style.bg_color = Color(0.11, 0.14, 0.19, 0.9)
	d_style.border_color = Color(0.3, 0.35, 0.42)
	d_style.border_width_left = 1
	d_style.border_width_right = 1
	d_style.border_width_top = 1
	d_style.border_width_bottom = 1
	d_style.corner_radius_top_left = 6
	d_style.corner_radius_top_right = 6
	d_style.corner_radius_bottom_left = 6
	d_style.corner_radius_bottom_right = 6
	d_style.content_margin_left = 12.0
	d_style.content_margin_right = 12.0
	d_style.content_margin_top = 8.0
	d_style.content_margin_bottom = 8.0
	dossier_panel.add_theme_stylebox_override("panel", d_style)

	var dossier_hbox = HBoxContainer.new()
	dossier_hbox.add_theme_constant_override("separation", 12)
	dossier_panel.add_child(dossier_hbox)

	# Entity Avatar Frame
	var av_frame = PanelContainer.new()
	av_frame.custom_minimum_size = Vector2(64, 64)
	var af_style = StyleBoxFlat.new()
	af_style.bg_color = Color(0.06, 0.08, 0.12, 1.0)
	af_style.border_color = Color(0.7, 0.6, 0.25)
	af_style.border_width_left = 1
	af_style.border_width_right = 1
	af_style.border_width_top = 1
	af_style.border_width_bottom = 1
	af_style.corner_radius_top_left = 4
	af_style.corner_radius_top_right = 4
	af_style.corner_radius_bottom_left = 4
	af_style.corner_radius_bottom_right = 4
	av_frame.add_theme_stylebox_override("panel", af_style)

	dossier_avatar = TextureRect.new()
	dossier_avatar.custom_minimum_size = Vector2(60, 60)
	dossier_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dossier_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dossier_avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists("res://assets/ui/island_lord.png"):
		dossier_avatar.texture = load("res://assets/ui/island_lord.png")
	av_frame.add_child(dossier_avatar)
	dossier_hbox.add_child(av_frame)

	# Stats & Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	dossier_hbox.add_child(info_vbox)

	dossier_name = Label.new()
	dossier_name.text = "Island Overseer"
	dossier_name.add_theme_font_size_override("font_size", 14)
	dossier_name.add_theme_color_override("font_color", Color(0.95, 0.88, 0.4))
	info_vbox.add_child(dossier_name)

	# Health bar
	var hp_box = HBoxContainer.new()
	hp_box.add_theme_constant_override("separation", 8)
	dossier_hp_bar = ProgressBar.new()
	dossier_hp_bar.custom_minimum_size = Vector2(160, 14)
	dossier_hp_bar.show_percentage = false
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.2, 0.75, 0.35)
	hp_fill.corner_radius_top_left = 3
	hp_fill.corner_radius_top_right = 3
	hp_fill.corner_radius_bottom_left = 3
	hp_fill.corner_radius_bottom_right = 3
	dossier_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_box.add_child(dossier_hp_bar)

	dossier_hp_text = Label.new()
	dossier_hp_text.text = "100 / 100 HP"
	dossier_hp_text.add_theme_font_size_override("font_size", 11)
	hp_box.add_child(dossier_hp_text)
	info_vbox.add_child(hp_box)

	dossier_stats = Label.new()
	dossier_stats.text = "Select a unit, building or resource node to command."
	dossier_stats.add_theme_font_size_override("font_size", 11)
	dossier_stats.add_theme_color_override("font_color", Color(0.8, 0.82, 0.85))
	info_vbox.add_child(dossier_stats)

	dossier_actions_box = HBoxContainer.new()
	dossier_actions_box.add_theme_constant_override("separation", 6)
	info_vbox.add_child(dossier_actions_box)

	hbox.add_child(dossier_panel)

	# --- Module 3: Command & Build Console (Right) ---
	command_panel = PanelContainer.new()
	command_panel.custom_minimum_size = Vector2(490, 144)
	var c_style = StyleBoxFlat.new()
	c_style.bg_color = Color(0.1, 0.13, 0.18, 0.94)
	c_style.border_color = Color(0.4, 0.45, 0.5)
	c_style.border_width_left = 1
	c_style.border_width_right = 1
	c_style.border_width_top = 1
	c_style.border_width_bottom = 1
	c_style.corner_radius_top_left = 6
	c_style.corner_radius_top_right = 6
	c_style.corner_radius_bottom_left = 6
	c_style.corner_radius_bottom_right = 6
	c_style.content_margin_left = 10.0
	c_style.content_margin_right = 10.0
	c_style.content_margin_top = 6.0
	c_style.content_margin_bottom = 6.0
	command_panel.add_theme_stylebox_override("panel", c_style)

	var c_vbox = VBoxContainer.new()
	c_vbox.add_theme_constant_override("separation", 6)
	command_panel.add_child(c_vbox)

	var header_hbox = HBoxContainer.new()
	command_title = Label.new()
	command_title.text = "🔨 CONSTRUCTION & ACTIONS"
	command_title.add_theme_font_size_override("font_size", 12)
	command_title.add_theme_color_override("font_color", Color(0.9, 0.8, 0.35))
	header_hbox.add_child(command_title)
	c_vbox.add_child(header_hbox)

	command_grid = GridContainer.new()
	command_grid.columns = 4
	command_grid.add_theme_constant_override("h_separation", 6)
	command_grid.add_theme_constant_override("v_separation", 4)
	c_vbox.add_child(command_grid)

	# Populate initial build catalog buttons
	populate_build_grid()
	hbox.add_child(command_panel)

func populate_build_grid() -> void:
	for child in command_grid.get_children():
		child.queue_free()

	for b_key in building_catalog.keys():
		var data = building_catalog[b_key]
		var btn = create_blueprint_card(b_key, data["name"], data["cost"], data["icon"], data["desc"])
		command_grid.add_child(btn)

func create_blueprint_card(b_key: String, title: String, cost: String, icon_path: String, desc: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(110, 48)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.14, 0.18, 0.24, 0.95)
	btn_style.border_color = Color(0.35, 0.42, 0.5)
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.content_margin_left = 4.0
	btn_style.content_margin_right = 4.0
	btn.add_theme_stylebox_override("normal", btn_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	if ResourceLoader.exists(icon_path):
		var tr = TextureRect.new()
		tr.texture = load(icon_path)
		tr.custom_minimum_size = Vector2(30, 30)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(tr)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_lbl = Label.new()
	name_lbl.text = title
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	var cost_lbl = Label.new()
	cost_lbl.text = cost
	cost_lbl.add_theme_font_size_override("font_size", 9)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_lbl)
	hbox.add_child(vbox)

	btn.pressed.connect(func(): emit_signal("build_requested", b_key))
	btn.mouse_entered.connect(func(): show_tooltip(title, desc, cost, btn.global_position + Vector2(0, -90)))
	btn.mouse_exited.connect(hide_tooltip)
	return btn

# ─────────────────────────────────────────────────────────────────────────────
# 3. INTERACTIVE TOOLTIP & NOTIFICATION BANNER
# ─────────────────────────────────────────────────────────────────────────────
func build_tooltip_ui() -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.custom_minimum_size = Vector2(210, 80)
	var t_style = StyleBoxFlat.new()
	t_style.bg_color = Color(0.08, 0.1, 0.14, 0.98)
	t_style.border_color = Color(0.75, 0.6, 0.25)
	t_style.border_width_left = 1
	t_style.border_width_right = 1
	t_style.border_width_top = 1
	t_style.border_width_bottom = 1
	t_style.corner_radius_top_left = 6
	t_style.corner_radius_top_right = 6
	t_style.corner_radius_bottom_left = 6
	t_style.corner_radius_bottom_right = 6
	t_style.content_margin_left = 8.0
	t_style.content_margin_right = 8.0
	t_style.content_margin_top = 6.0
	t_style.content_margin_bottom = 6.0
	tooltip_panel.add_theme_stylebox_override("panel", t_style)
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tooltip_panel)

	var vbox = VBoxContainer.new()
	tooltip_panel.add_child(vbox)

	tooltip_title = Label.new()
	tooltip_title.text = "Item"
	tooltip_title.add_theme_font_size_override("font_size", 12)
	tooltip_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(tooltip_title)

	tooltip_desc = Label.new()
	tooltip_desc.text = "Description"
	tooltip_desc.add_theme_font_size_override("font_size", 10)
	tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(tooltip_desc)

	tooltip_cost = Label.new()
	tooltip_cost.text = "Cost"
	tooltip_cost.add_theme_font_size_override("font_size", 10)
	tooltip_cost.add_theme_color_override("font_color", Color(0.7, 0.9, 0.4))
	vbox.add_child(tooltip_cost)

func show_tooltip(title: String, desc: String, cost: String, pos: Vector2) -> void:
	tooltip_title.text = title
	tooltip_desc.text = desc
	tooltip_cost.text = "Cost: " + cost
	tooltip_panel.position = pos
	tooltip_panel.visible = true

func hide_tooltip() -> void:
	if tooltip_panel:
		tooltip_panel.visible = false

func build_notification_banner() -> void:
	notif_banner = PanelContainer.new()
	notif_banner.anchor_left = 0.5
	notif_banner.anchor_right = 0.5
	notif_banner.offset_left = -280.0
	notif_banner.offset_top = 62.0
	notif_banner.offset_right = 280.0
	notif_banner.offset_bottom = 100.0

	var n_style = StyleBoxFlat.new()
	n_style.bg_color = Color(0.12, 0.1, 0.05, 0.94)
	n_style.border_color = Color(0.9, 0.75, 0.2)
	n_style.border_width_left = 2
	n_style.border_width_right = 2
	n_style.border_width_top = 2
	n_style.border_width_bottom = 2
	n_style.corner_radius_top_left = 8
	n_style.corner_radius_top_right = 8
	n_style.corner_radius_bottom_left = 8
	n_style.corner_radius_bottom_right = 8
	notif_banner.add_theme_stylebox_override("panel", n_style)
	notif_banner.visible = false
	add_child(notif_banner)

	notif_label = Label.new()
	notif_label.text = "Alert"
	notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notif_label.add_theme_font_size_override("font_size", 14)
	notif_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
	notif_banner.add_child(notif_label)

func show_notification(msg: String) -> void:
	notif_label.text = msg
	notif_banner.visible = true
	notif_timer = 4.5

func build_game_over_modal() -> void:
	game_over_modal = PanelContainer.new()
	game_over_modal.anchor_left = 0.5
	game_over_modal.anchor_top = 0.5
	game_over_modal.anchor_right = 0.5
	game_over_modal.anchor_bottom = 0.5
	game_over_modal.offset_left = -220.0
	game_over_modal.offset_top = -120.0
	game_over_modal.offset_right = 220.0
	game_over_modal.offset_bottom = 120.0
	game_over_modal.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.98)
	style.border_color = Color(0.9, 0.75, 0.2)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	game_over_modal.add_theme_stylebox_override("panel", style)
	add_child(game_over_modal)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_modal.add_child(vbox)

	game_over_title = Label.new()
	game_over_title.text = "VICTORY"
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(game_over_title)

	game_over_sub = Label.new()
	game_over_sub.text = "You conquered the archipelago!"
	game_over_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_sub.add_theme_font_size_override("font_size", 13)
	vbox.add_child(game_over_sub)

	var play_again_btn = Button.new()
	play_again_btn.text = "Play Again"
	play_again_btn.custom_minimum_size = Vector2(140, 36)
	play_again_btn.pressed.connect(func(): get_tree().reload_current_scene())
	vbox.add_child(play_again_btn)

func _process(delta: float) -> void:
	if notif_timer > 0.0:
		notif_timer -= delta
		if notif_timer <= 0.0:
			notif_banner.visible = false

# ─────────────────────────────────────────────────────────────────────────────
# 4. GAME MANAGER EVENT HANDLERS
# ─────────────────────────────────────────────────────────────────────────────
func _on_resources_changed(res: Dictionary) -> void:
	food_label.text = str(res.get("food", 0))
	wood_label.text = str(res.get("wood", 0))
	stone_label.text = str(res.get("stone", 0))
	gold_label.text = str(res.get("gold", 0))
	var pop = res.get("population", 0)
	var max_pop = res.get("max_population", 10)
	pop_label.text = "👥 %d / %d" % [pop, max_pop]
	update_age_advancement_state()

func update_age_advancement_state() -> void:
	if not GameManager.instance or not age_button:
		return

	var cur = GameManager.instance.current_age
	var cur_name = GameManager.instance.age_names[cur]
	era_badge_lbl.text = "🏛️ " + cur_name + " (Era %d)" % [cur + 1]

	if cur >= GameManager.Age.MEDIEVAL_AGE:
		age_button.text = "👑 " + cur_name + " (Apex Empire)"
		age_button.disabled = true
	else:
		var next_name = GameManager.instance.age_names[cur + 1]
		var cost = GameManager.instance.get_next_age_cost()
		var cost_str = ""
		for k in cost.keys():
			cost_str += str(cost[k]) + k.left(1).to_upper() + " "
		age_button.text = "Advance -> " + next_name + " (" + cost_str.strip_edges() + ")"
		age_button.disabled = not GameManager.instance.can_advance_age()

func _on_age_advanced(_new_age: String) -> void:
	update_age_advancement_state()

func _on_age_button_pressed() -> void:
	emit_signal("age_advance_requested")

func _on_game_state_changed(state: String) -> void:
	game_over_modal.visible = true
	if state == "victory":
		game_over_title.text = "👑 ARCHIPELAGO CONQUERED!"
		game_over_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		game_over_sub.text = "The enemy totem has fallen. Your island empire reigns supreme!"
	else:
		game_over_title.text = "💀 DEFEAT!"
		game_over_title.add_theme_color_override("font_color", Color(0.95, 0.2, 0.2))
		game_over_sub.text = "Your Town Center was destroyed by the raiders."

func _on_minimap_clicked(world_target: Vector3) -> void:
	emit_signal("minimap_clicked", world_target)

# ─────────────────────────────────────────────────────────────────────────────
# 5. SELECTION DOSSIER & ACTIONS
# ─────────────────────────────────────────────────────────────────────────────
func _on_selection_changed(entities: Array) -> void:
	for child in dossier_actions_box.get_children():
		child.queue_free()

	if entities.is_empty():
		dossier_name.text = "Island Overseer"
		dossier_stats.text = "Select any unit, building or resource node to command."
		dossier_hp_bar.value = 100
		dossier_hp_text.text = "--"
		dossier_avatar.texture = load("res://assets/ui/island_lord.png") if ResourceLoader.exists("res://assets/ui/island_lord.png") else null
		populate_build_grid()
		return

	var first = entities[0]

	if first is BuildingBase:
		var b: BuildingBase = first
		dossier_name.text = b.building_type.replace("_", " ").capitalize() + " (" + b.team.capitalize() + ")"
		dossier_hp_bar.max_value = b.max_hp
		dossier_hp_bar.value = b.current_hp
		dossier_hp_text.text = "%d / %d HP" % [b.current_hp, b.max_hp]
		dossier_stats.text = "Structural Integrity: %d%%" % [int(float(b.current_hp) / float(b.max_hp) * 100)]

		var icon_path = "res://assets/ui/icon_" + b.building_type + ".png"
		if ResourceLoader.exists(icon_path):
			dossier_avatar.texture = load(icon_path)

		if b.team == "player":
			setup_building_action_grid(b)

	elif first is RoyalKnight:
		var rk: RoyalKnight = first
		dossier_name.text = "Royal Knight (Heavy Cavalry)"
		dossier_hp_bar.max_value = rk.max_hp
		dossier_hp_bar.value = rk.current_hp
		dossier_hp_text.text = "%d / %d HP" % [rk.current_hp, rk.max_hp]
		dossier_stats.text = "⚔️ Lance: 32 Dmg | 🏃 Speed: 8.5 | Heavy Armor"
		if ResourceLoader.exists("res://assets/characters/royal_knight.png"):
			dossier_avatar.texture = load("res://assets/characters/royal_knight.png")

	elif first is HeroCommander:
		var hero: HeroCommander = first
		dossier_name.text = "Island Lord (Supreme Commander)"
		dossier_hp_bar.max_value = hero.max_hp
		dossier_hp_bar.value = hero.current_hp
		dossier_hp_text.text = "%d / %d HP" % [hero.current_hp, hero.max_hp]
		dossier_stats.text = "⚔️ Broadsword: 28 Dmg | 👑 Inspiring Aura (12m)"
		if ResourceLoader.exists("res://assets/ui/island_lord.png"):
			dossier_avatar.texture = load("res://assets/ui/island_lord.png")

	elif first is Catapult:
		var cat: Catapult = first
		dossier_name.text = "Siege Catapult"
		dossier_hp_bar.max_value = cat.max_hp
		dossier_hp_bar.value = cat.current_hp
		dossier_hp_text.text = "%d / %d HP" % [cat.current_hp, cat.max_hp]
		dossier_stats.text = "💥 Siege Boulder: 45 Dmg (24m Range) | 🏃 Speed: 3.4"
		if ResourceLoader.exists("res://assets/ui/icon_catapult_workshop.png"):
			dossier_avatar.texture = load("res://assets/ui/icon_catapult_workshop.png")

	elif first is WarGalleon:
		var wg: WarGalleon = first
		dossier_name.text = "War Galleon (Artillery Warship)"
		dossier_hp_bar.max_value = wg.max_hp
		dossier_hp_bar.value = wg.current_hp
		dossier_hp_text.text = "%d / %d HP" % [wg.current_hp, wg.max_hp]
		dossier_stats.text = "💣 Broadside Cannons: 35 Dmg | ⚓ Heavy Warship"
		if ResourceLoader.exists("res://assets/ui/icon_harbor.png"):
			dossier_avatar.texture = load("res://assets/ui/icon_harbor.png")

	elif first is TransportShip:
		var ship: TransportShip = first
		dossier_name.text = "Galley Transport"
		dossier_hp_bar.max_value = ship.max_hp
		dossier_hp_bar.value = ship.current_hp
		dossier_hp_text.text = "%d / %d HP" % [ship.current_hp, ship.max_hp]
		dossier_stats.text = "Troops Embarked: %d / %d" % [ship.embarked_units.size(), ship.max_capacity]

		var disembark_btn = Button.new()
		disembark_btn.text = "⛵ Disembark All Troops"
		disembark_btn.custom_minimum_size = Vector2(160, 32)
		disembark_btn.pressed.connect(func(): ship.disembark_all(ship.global_position))
		dossier_actions_box.add_child(disembark_btn)

	elif first is UnitBase:
		var u: UnitBase = first
		dossier_name.text = u.unit_name + " (" + u.team.capitalize() + ")"
		dossier_hp_bar.max_value = u.max_hp
		dossier_hp_bar.value = u.current_hp
		dossier_hp_text.text = "%d / %d HP" % [u.current_hp, u.max_hp]
		dossier_stats.text = "⚔️ Attack: %d | 🏃 Speed: %.1f | Range: %.1fm" % [u.attack_damage, u.move_speed, u.attack_range]

func setup_building_action_grid(b: BuildingBase) -> void:
	for child in command_grid.get_children():
		child.queue_free()

	command_title.text = "⚔️ " + b.building_type.replace("_", " ").to_upper() + " TRAINING QUEUE"

	match b.building_type:
		"town_center":
			add_training_card("villager", "Villager", "50F", "res://assets/ui/icon_food.png", "Harvests resources and builds structures.", b)
			add_training_card("hero_commander", "Island Lord", "150F, 150G", "res://assets/ui/island_lord.png", "Supreme commander with Inspiring Aura.", b)
		"barracks":
			add_training_card("spearman", "Spearman", "60F, 30W", "res://assets/ui/icon_barracks.png", "Line infantry, strong against cavalry.", b)
			add_training_card("archer", "Archer", "50F, 50W", "res://assets/ui/icon_barracks.png", "Ranged marksman.", b)
			add_training_card("knight", "Royal Knight", "100F, 80G", "res://assets/characters/royal_knight.png", "Fast heavy cavalry shock unit.", b)
		"harbor":
			add_training_card("transport_ship", "Galley", "120W, 40G", "res://assets/ui/icon_harbor.png", "Naval transport for amphibious troops.", b)
			add_training_card("war_galleon", "War Galleon", "220W, 80S, 100G", "res://assets/ui/icon_harbor.png", "Armed warship with broadside cannons.", b)
		"catapult_workshop":
			add_training_card("catapult", "Catapult", "150W, 100S, 50G", "res://assets/ui/icon_catapult_workshop.png", "Heavy siege weapon that hurls boulders.", b)
		_:
			populate_build_grid()

func add_training_card(type: String, title: String, cost: String, icon_path: String, desc: String, b: BuildingBase) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(110, 48)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.14, 0.18, 0.24, 0.95)
	btn_style.border_color = Color(0.35, 0.42, 0.5)
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4
	btn_style.content_margin_left = 4.0
	btn_style.content_margin_right = 4.0
	btn.add_theme_stylebox_override("normal", btn_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	if ResourceLoader.exists(icon_path):
		var tr = TextureRect.new()
		tr.texture = load(icon_path)
		tr.custom_minimum_size = Vector2(30, 30)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(tr)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_lbl = Label.new()
	name_lbl.text = title
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	var cost_lbl = Label.new()
	cost_lbl.text = cost
	cost_lbl.add_theme_font_size_override("font_size", 9)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_lbl)
	hbox.add_child(vbox)

	btn.pressed.connect(func(): emit_signal("train_unit_requested", type, b))
	btn.mouse_entered.connect(func(): show_tooltip("Train " + title, desc, cost, btn.global_position + Vector2(0, -90)))
	btn.mouse_exited.connect(hide_tooltip)
	command_grid.add_child(btn)
