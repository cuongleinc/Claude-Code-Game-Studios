class_name RTSHud
extends Control

signal build_requested(building_type: String)
signal train_unit_requested(unit_type: String, building: BuildingBase)
signal age_advance_requested()
signal minimap_clicked(world_pos: Vector3)

# ─────────────────────────────────────────────────────────────────────────────
# UI ASSETS & CATALOGS
# ─────────────────────────────────────────────────────────────────────────────
const ICON_IDLE_VILLAGER = "res://assets/ui/icon_idle_villager.png"
const ICON_HAMMER_BUILD = "res://assets/ui/icon_hammer_build.png"
const ICON_ERA_CREST = "res://assets/ui/icon_era_crest.png"
const ICON_RAID_WARNING = "res://assets/ui/icon_raid_warning.png"
const ICON_SQUAD_SPEARMAN = "res://assets/ui/icon_squad_spearman.png"
const ICON_SQUAD_ARCHER = "res://assets/ui/icon_squad_archer.png"
const ICON_SQUAD_KNIGHT = "res://assets/ui/icon_squad_knight.png"

# Top Bar Elements
var lord_avatar_rect: TextureRect
var empire_name_lbl: Label
var era_badge_lbl: Label
var era_icon_rect: TextureRect
var food_label: Label
var wood_label: Label
var stone_label: Label
var gold_label: Label
var pop_label: Label
var idle_villager_btn: Button
var idle_villager_tr: TextureRect
var idle_villager_lbl: Label
var age_button: Button
var age_button_lbl: Label
var speed_buttons: Array[Button] = []

# Floating Bottom-Left Radar Widget
var radar_container: PanelContainer
var minimap_radar: MinimapRadar

# Floating Bottom-Center Contextual Inspector (Selection Capsule)
var inspector_capsule: PanelContainer
var inspector_empty_box: HBoxContainer
var inspector_single_box: HBoxContainer
var inspector_squad_box: VBoxContainer

# Single Entity Dossier Controls
var dossier_avatar: TextureRect
var dossier_name: Label
var dossier_type_badge: Label
var dossier_hp_bar: ProgressBar
var dossier_hp_text: Label
var dossier_stats: Label
var dossier_actions_grid: GridContainer
var training_progress_box: VBoxContainer
var training_progress_bar: ProgressBar
var training_progress_lbl: Label
var current_inspected_building: BuildingBase

# Squad Multi-Selection Controls
var squad_title_lbl: Label
var squad_hp_bar: ProgressBar
var squad_hp_lbl: Label
var squad_chips_box: HBoxContainer
var current_selected_entities: Array = []

# Floating Bottom-Right Collapsible Build Drawer
var build_toggle_btn: Button
var build_drawer_panel: PanelContainer
var build_grid: GridContainer
var is_build_drawer_open: bool = true

# Tooltip & Notification
var tooltip_panel: PanelContainer
var tooltip_title: Label
var tooltip_desc: Label
var tooltip_cost: Label
var notif_banner: PanelContainer
var notif_icon: TextureRect
var notif_label: Label
var notif_timer: float = 0.0

# Game Over Modal
var game_over_modal: PanelContainer
var game_over_title: Label
var game_over_sub: Label

# Idle villager cycling
var last_idle_villager_index: int = -1
var idle_update_timer: float = 0.0

# Cached building metadata
var building_catalog = {
	"house": {"name": "Cottage", "cost_str": "50W", "cost": {"wood": 50}, "icon": "res://assets/ui/icon_house.png", "desc": "Increases population cap by 5."},
	"farm": {"name": "Farm", "cost_str": "60W", "cost": {"wood": 60}, "icon": "res://assets/ui/icon_farm.png", "desc": "Generates continuous passive food supply."},
	"lumber_camp": {"name": "Lumber Camp", "cost_str": "80W", "cost": {"wood": 80}, "icon": "res://assets/ui/icon_lumber_camp.png", "desc": "Harvest drop-off for nearby forests."},
	"barracks": {"name": "Barracks", "cost_str": "120W, 60S", "cost": {"wood": 120, "stone": 60}, "icon": "res://assets/ui/icon_barracks.png", "desc": "Trains Spearmen, Archers, and Royal Knights."},
	"guard_tower": {"name": "Guard Tower", "cost_str": "100W, 80S", "cost": {"wood": 100, "stone": 80}, "icon": "res://assets/ui/icon_guard_tower.png", "desc": "Shoots defensive arrows at enemy raiders (18m)."},
	"stone_wall": {"name": "Stone Wall", "cost_str": "25S", "cost": {"stone": 25}, "icon": "res://assets/ui/icon_stone_wall.png", "desc": "Heavy fortifications to block landing parties."},
	"harbor": {"name": "Harbor", "cost_str": "150W, 80S", "cost": {"wood": 150, "stone": 80}, "icon": "res://assets/ui/icon_harbor.png", "desc": "Constructs Galley Transports and War Galleons."},
	"catapult_workshop": {"name": "Workshop", "cost_str": "180W, 120S, 60G", "cost": {"wood": 180, "stone": 120, "gold": 60}, "icon": "res://assets/ui/icon_catapult_workshop.png", "desc": "Constructs heavy siege Catapults."}
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	build_top_ribbon()
	build_floating_radar()
	build_floating_inspector()
	build_floating_builder()
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

	update_idle_villagers_display()

# ─────────────────────────────────────────────────────────────────────────────
# 1. TACTILE TOY / LEGO BEVEL STYLE FACTORY
# ─────────────────────────────────────────────────────────────────────────────
func create_toy_panel_style(bg_col: Color, border_col: Color, corner_rad: int = 10, margins: Vector4 = Vector4(10, 10, 8, 8)) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_color = border_col
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 4 # Beveled bottom shadow
	style.corner_radius_top_left = corner_rad
	style.corner_radius_top_right = corner_rad
	style.corner_radius_bottom_left = corner_rad
	style.corner_radius_bottom_right = corner_rad
	style.content_margin_left = margins.x
	style.content_margin_right = margins.y
	style.content_margin_top = margins.z
	style.content_margin_bottom = margins.w
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style

func create_toy_button_style(bg_col: Color, border_col: Color, is_pressed: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_color = border_col
	style.border_width_left = 1
	style.border_width_right = 1
	if is_pressed:
		style.border_width_top = 3
		style.border_width_bottom = 1
	else:
		style.border_width_top = 1
		style.border_width_bottom = 3 # Raised button bevel
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0 if not is_pressed else 6.0
	style.content_margin_bottom = 4.0 if not is_pressed else 2.0
	return style

# ─────────────────────────────────────────────────────────────────────────────
# 2. TOP EMPIRE FLOATING RIBBON
# ─────────────────────────────────────────────────────────────────────────────
func build_top_ribbon() -> void:
	var top_bar = PanelContainer.new()
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_left = 12.0
	top_bar.offset_right = -12.0
	top_bar.offset_top = 8.0
	top_bar.offset_bottom = 58.0
	top_bar.custom_minimum_size = Vector2(0, 50)

	var style = create_toy_panel_style(Color(0.09, 0.12, 0.17, 0.94), Color(0.85, 0.72, 0.32), 12, Vector4(12, 12, 6, 6))
	top_bar.add_theme_stylebox_override("panel", style)
	add_child(top_bar)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.add_theme_constant_override("separation", 14)
	top_bar.add_child(hbox)

	# Faction Crest & Name
	var crest_box = HBoxContainer.new()
	crest_box.add_theme_constant_override("separation", 8)

	var lord_path = "res://assets/ui/island_lord.png"
	if ResourceLoader.exists(lord_path):
		var avatar_panel = PanelContainer.new()
		var a_style = create_toy_panel_style(Color(0.18, 0.15, 0.10, 1.0), Color(0.95, 0.85, 0.35), 6, Vector4(2, 2, 2, 2))
		avatar_panel.add_theme_stylebox_override("panel", a_style)

		lord_avatar_rect = TextureRect.new()
		lord_avatar_rect.texture = load(lord_path)
		lord_avatar_rect.custom_minimum_size = Vector2(32, 32)
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
	empire_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title_vbox.add_child(empire_name_lbl)

	era_badge_lbl = Label.new()
	era_badge_lbl.text = "🏛️ Stone Age (Era I)"
	era_badge_lbl.add_theme_font_size_override("font_size", 10)
	era_badge_lbl.add_theme_color_override("font_color", Color(0.75, 0.88, 0.98))
	title_vbox.add_child(era_badge_lbl)
	crest_box.add_child(title_vbox)
	hbox.add_child(crest_box)

	hbox.add_child(create_v_separator())

	# Resource Tablets (Vibrant Toy Gem Colors)
	food_label = create_resource_pill(hbox, "res://assets/ui/icon_food.png", "200", Color(0.12, 0.28, 0.15, 0.92), Color(0.35, 0.75, 0.40))
	wood_label = create_resource_pill(hbox, "res://assets/ui/icon_wood.png", "300", Color(0.28, 0.18, 0.10, 0.92), Color(0.72, 0.50, 0.32))
	stone_label = create_resource_pill(hbox, "res://assets/ui/icon_stone.png", "150", Color(0.16, 0.22, 0.28, 0.92), Color(0.60, 0.70, 0.80))
	gold_label = create_resource_pill(hbox, "res://assets/ui/icon_gold.png", "100", Color(0.32, 0.25, 0.06, 0.92), Color(0.98, 0.80, 0.20))
	pop_label = create_resource_pill(hbox, "", "👥 3/30", Color(0.10, 0.18, 0.28, 0.92), Color(0.35, 0.65, 0.95))

	# Idle Villager Locator Pill Button
	idle_villager_btn = Button.new()
	idle_villager_btn.custom_minimum_size = Vector2(115, 34)
	idle_villager_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var iv_style = create_toy_button_style(Color(0.24, 0.18, 0.08, 0.95), Color(0.95, 0.75, 0.25))
	idle_villager_btn.add_theme_stylebox_override("normal", iv_style)
	idle_villager_btn.add_theme_stylebox_override("hover", create_toy_button_style(Color(0.34, 0.26, 0.10, 0.98), Color(1.0, 0.88, 0.35)))
	idle_villager_btn.pressed.connect(_on_idle_villager_clicked)

	var iv_hbox = HBoxContainer.new()
	iv_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	iv_hbox.add_theme_constant_override("separation", 6)
	iv_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	idle_villager_btn.add_child(iv_hbox)

	if ResourceLoader.exists(ICON_IDLE_VILLAGER):
		idle_villager_tr = TextureRect.new()
		idle_villager_tr.texture = load(ICON_IDLE_VILLAGER)
		idle_villager_tr.custom_minimum_size = Vector2(24, 24)
		idle_villager_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		idle_villager_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		idle_villager_tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		idle_villager_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		iv_hbox.add_child(idle_villager_tr)

	idle_villager_lbl = Label.new()
	idle_villager_lbl.text = "Idle: 0"
	idle_villager_lbl.add_theme_font_size_override("font_size", 12)
	idle_villager_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	idle_villager_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	iv_hbox.add_child(idle_villager_lbl)
	hbox.add_child(idle_villager_btn)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Era Advancement Sigil Button
	age_button = Button.new()
	age_button.custom_minimum_size = Vector2(265, 34)
	age_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var ab_style = create_toy_button_style(Color(0.24, 0.17, 0.08, 0.95), Color(0.95, 0.82, 0.28))
	age_button.add_theme_stylebox_override("normal", ab_style)
	age_button.add_theme_stylebox_override("hover", create_toy_button_style(Color(0.34, 0.25, 0.10, 0.98), Color(1.0, 0.92, 0.38)))
	age_button.pressed.connect(_on_age_button_pressed)

	var ab_hbox = HBoxContainer.new()
	ab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ab_hbox.add_theme_constant_override("separation", 6)
	ab_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	age_button.add_child(ab_hbox)

	if ResourceLoader.exists(ICON_ERA_CREST):
		era_icon_rect = TextureRect.new()
		era_icon_rect.texture = load(ICON_ERA_CREST)
		era_icon_rect.custom_minimum_size = Vector2(22, 22)
		era_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		era_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		era_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		era_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ab_hbox.add_child(era_icon_rect)

	age_button_lbl = Label.new()
	age_button_lbl.text = "Advance -> Bronze Age"
	age_button_lbl.add_theme_font_size_override("font_size", 11)
	age_button_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7))
	age_button_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ab_hbox.add_child(age_button_lbl)
	hbox.add_child(age_button)

	# Speed controls
	var speed_box = HBoxContainer.new()
	speed_box.add_theme_constant_override("separation", 4)
	add_speed_button(speed_box, "⏸", 0.0)
	add_speed_button(speed_box, "▶ 1x", 1.0)
	add_speed_button(speed_box, "⏩ 2x", 2.0)
	hbox.add_child(speed_box)

func create_resource_pill(parent: Control, icon_path: String, val: String, bg_col: Color, border_col: Color) -> Label:
	var pill = PanelContainer.new()
	var p_style = create_toy_panel_style(bg_col, border_col, 10, Vector4(8, 10, 3, 3))
	pill.add_theme_stylebox_override("panel", p_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	pill.add_child(hbox)

	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tr = TextureRect.new()
		tr.texture = load(icon_path)
		tr.custom_minimum_size = Vector2(18, 18)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hbox.add_child(tr)

	var lbl = Label.new()
	lbl.text = val
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.98, 0.98, 0.98))
	hbox.add_child(lbl)

	parent.add_child(pill)
	return lbl

func create_v_separator() -> Control:
	var sep = VSeparator.new()
	sep.custom_minimum_size = Vector2(2, 24)
	return sep

func add_speed_button(parent: Control, txt: String, speed: float) -> void:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(38, 28)
	btn.add_theme_font_size_override("font_size", 11)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", create_toy_button_style(Color(0.12, 0.16, 0.22, 0.9), Color(0.4, 0.5, 0.6)))
	btn.add_theme_stylebox_override("hover", create_toy_button_style(Color(0.18, 0.24, 0.32, 0.95), Color(0.6, 0.75, 0.9)))
	btn.pressed.connect(func():
		if GameManager.instance:
			GameManager.instance.set_game_speed(speed)
	)
	speed_buttons.append(btn)
	parent.add_child(btn)

# ─────────────────────────────────────────────────────────────────────────────
# 3. FLOATING BOTTOM-LEFT MINI-RADAR WIDGET
# ─────────────────────────────────────────────────────────────────────────────
func build_floating_radar() -> void:
	radar_container = PanelContainer.new()
	radar_container.anchor_left = 0.0
	radar_container.anchor_right = 0.0
	radar_container.anchor_top = 1.0
	radar_container.anchor_bottom = 1.0
	radar_container.offset_left = 12.0
	radar_container.offset_top = -188.0
	radar_container.offset_right = 195.0
	radar_container.offset_bottom = -12.0
	radar_container.custom_minimum_size = Vector2(183, 176)

	var style = create_toy_panel_style(Color(0.08, 0.11, 0.16, 0.96), Color(0.78, 0.65, 0.28), 10, Vector4(4, 4, 4, 4))
	radar_container.add_theme_stylebox_override("panel", style)
	add_child(radar_container)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	radar_container.add_child(vbox)

	# Quick Nav Header Bar
	var nav_bar = HBoxContainer.new()
	nav_bar.add_theme_constant_override("separation", 4)

	var home_btn = Button.new()
	home_btn.text = "🏰 Capital"
	home_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_btn.custom_minimum_size = Vector2(0, 22)
	home_btn.add_theme_font_size_override("font_size", 10)
	home_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	home_btn.add_theme_stylebox_override("normal", create_toy_button_style(Color(0.12, 0.22, 0.16, 0.9), Color(0.35, 0.7, 0.4)))
	home_btn.pressed.connect(func(): if minimap_radar: minimap_radar.focus_on_capital())
	nav_bar.add_child(home_btn)

	var enemy_btn = Button.new()
	enemy_btn.text = "🏴 Enemy"
	enemy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_btn.custom_minimum_size = Vector2(0, 22)
	enemy_btn.add_theme_font_size_override("font_size", 10)
	enemy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	enemy_btn.add_theme_stylebox_override("normal", create_toy_button_style(Color(0.24, 0.12, 0.12, 0.9), Color(0.75, 0.35, 0.35)))
	enemy_btn.pressed.connect(func(): if minimap_radar: minimap_radar.focus_on_enemy())
	nav_bar.add_child(enemy_btn)
	vbox.add_child(nav_bar)

	# Minimap Radar View
	minimap_radar = MinimapRadar.new()
	minimap_radar.map_position_clicked.connect(_on_minimap_clicked)
	vbox.add_child(minimap_radar)

# ─────────────────────────────────────────────────────────────────────────────
# 4. FLOATING BOTTOM-CENTER CONTEXTUAL INSPECTOR
# ─────────────────────────────────────────────────────────────────────────────
func build_floating_inspector() -> void:
	inspector_capsule = PanelContainer.new()
	inspector_capsule.anchor_left = 0.5
	inspector_capsule.anchor_right = 0.5
	inspector_capsule.anchor_top = 1.0
	inspector_capsule.anchor_bottom = 1.0
	inspector_capsule.offset_left = -210.0
	inspector_capsule.offset_right = 210.0
	inspector_capsule.offset_top = -146.0
	inspector_capsule.offset_bottom = -12.0
	inspector_capsule.custom_minimum_size = Vector2(420, 134)

	var style = create_toy_panel_style(Color(0.09, 0.12, 0.18, 0.95), Color(0.65, 0.55, 0.3), 10, Vector4(10, 10, 8, 8))
	inspector_capsule.add_theme_stylebox_override("panel", style)
	add_child(inspector_capsule)

	# Box 1: Empty state (Slim minimalist status bar)
	inspector_empty_box = HBoxContainer.new()
	inspector_empty_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var empty_lbl = Label.new()
	empty_lbl.text = "🌴 Island Realm — Select any villager, soldier, or building to command."
	empty_lbl.add_theme_font_size_override("font_size", 12)
	empty_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	inspector_empty_box.add_child(empty_lbl)
	inspector_capsule.add_child(inspector_empty_box)

	# Box 2: Single Entity Selection
	inspector_single_box = HBoxContainer.new()
	inspector_single_box.add_theme_constant_override("separation", 12)
	inspector_single_box.visible = false
	inspector_capsule.add_child(inspector_single_box)

	# Avatar frame
	var av_frame = PanelContainer.new()
	av_frame.custom_minimum_size = Vector2(64, 64)
	av_frame.add_theme_stylebox_override("panel", create_toy_panel_style(Color(0.06, 0.08, 0.12, 1.0), Color(0.85, 0.72, 0.3), 6, Vector4(2, 2, 2, 2)))

	dossier_avatar = TextureRect.new()
	dossier_avatar.custom_minimum_size = Vector2(60, 60)
	dossier_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dossier_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dossier_avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	av_frame.add_child(dossier_avatar)
	inspector_single_box.add_child(av_frame)

	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	inspector_single_box.add_child(info_vbox)

	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 8)
	dossier_name = Label.new()
	dossier_name.text = "Entity Name"
	dossier_name.add_theme_font_size_override("font_size", 13)
	dossier_name.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	title_hbox.add_child(dossier_name)

	dossier_type_badge = Label.new()
	dossier_type_badge.text = "[Player]"
	dossier_type_badge.add_theme_font_size_override("font_size", 10)
	dossier_type_badge.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title_hbox.add_child(dossier_type_badge)
	info_vbox.add_child(title_hbox)

	# Health bar
	var hp_box = HBoxContainer.new()
	hp_box.add_theme_constant_override("separation", 8)
	dossier_hp_bar = ProgressBar.new()
	dossier_hp_bar.custom_minimum_size = Vector2(160, 12)
	dossier_hp_bar.show_percentage = false
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.2, 0.8, 0.35)
	hp_fill.corner_radius_top_left = 4
	hp_fill.corner_radius_top_right = 4
	hp_fill.corner_radius_bottom_left = 4
	hp_fill.corner_radius_bottom_right = 4
	dossier_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_box.add_child(dossier_hp_bar)

	dossier_hp_text = Label.new()
	dossier_hp_text.text = "100 / 100 HP"
	dossier_hp_text.add_theme_font_size_override("font_size", 11)
	hp_box.add_child(dossier_hp_text)
	info_vbox.add_child(hp_box)

	dossier_stats = Label.new()
	dossier_stats.text = "Unit statistics"
	dossier_stats.add_theme_font_size_override("font_size", 10)
	dossier_stats.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	info_vbox.add_child(dossier_stats)

	# Production / Actions Grid
	dossier_actions_grid = GridContainer.new()
	dossier_actions_grid.columns = 3
	dossier_actions_grid.add_theme_constant_override("h_separation", 6)
	dossier_actions_grid.add_theme_constant_override("v_separation", 4)
	info_vbox.add_child(dossier_actions_grid)

	# Real-time Training Progress Bar
	training_progress_box = VBoxContainer.new()
	training_progress_box.add_theme_constant_override("separation", 2)
	training_progress_box.visible = false

	training_progress_lbl = Label.new()
	training_progress_lbl.text = "Training: Villager"
	training_progress_lbl.add_theme_font_size_override("font_size", 10)
	training_progress_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	training_progress_box.add_child(training_progress_lbl)

	training_progress_bar = ProgressBar.new()
	training_progress_bar.custom_minimum_size = Vector2(180, 8)
	training_progress_bar.show_percentage = false
	var tp_fill = StyleBoxFlat.new()
	tp_fill.bg_color = Color(0.95, 0.75, 0.2)
	tp_fill.corner_radius_top_left = 3
	tp_fill.corner_radius_top_right = 3
	tp_fill.corner_radius_bottom_left = 3
	tp_fill.corner_radius_bottom_right = 3
	training_progress_bar.add_theme_stylebox_override("fill", tp_fill)
	training_progress_box.add_child(training_progress_bar)
	info_vbox.add_child(training_progress_box)

	# Box 3: Squad Multi-Selection Inspector
	inspector_squad_box = VBoxContainer.new()
	inspector_squad_box.add_theme_constant_override("separation", 6)
	inspector_squad_box.visible = false
	inspector_capsule.add_child(inspector_squad_box)

	var squad_header = HBoxContainer.new()
	squad_header.add_theme_constant_override("separation", 8)
	squad_title_lbl = Label.new()
	squad_title_lbl.text = "⚔️ TACTICAL SQUAD (0 Units)"
	squad_title_lbl.add_theme_font_size_override("font_size", 13)
	squad_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	squad_header.add_child(squad_title_lbl)

	var squad_spacer = Control.new()
	squad_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	squad_header.add_child(squad_spacer)

	var halt_btn = Button.new()
	halt_btn.text = "🛑 Halt All"
	halt_btn.custom_minimum_size = Vector2(75, 24)
	halt_btn.add_theme_font_size_override("font_size", 10)
	halt_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	halt_btn.add_theme_stylebox_override("normal", create_toy_button_style(Color(0.25, 0.14, 0.14, 0.9), Color(0.75, 0.35, 0.35)))
	halt_btn.pressed.connect(_on_squad_halt_clicked)
	squad_header.add_child(halt_btn)
	inspector_squad_box.add_child(squad_header)

	var s_hp_box = HBoxContainer.new()
	s_hp_box.add_theme_constant_override("separation", 8)
	squad_hp_bar = ProgressBar.new()
	squad_hp_bar.custom_minimum_size = Vector2(240, 10)
	squad_hp_bar.show_percentage = false
	var s_hp_fill = StyleBoxFlat.new()
	s_hp_fill.bg_color = Color(0.2, 0.8, 0.4)
	s_hp_fill.corner_radius_top_left = 3
	s_hp_fill.corner_radius_top_right = 3
	s_hp_fill.corner_radius_bottom_left = 3
	s_hp_fill.corner_radius_bottom_right = 3
	squad_hp_bar.add_theme_stylebox_override("fill", s_hp_fill)
	s_hp_box.add_child(squad_hp_bar)

	squad_hp_lbl = Label.new()
	squad_hp_lbl.text = "Squad HP: 100%"
	squad_hp_lbl.add_theme_font_size_override("font_size", 10)
	s_hp_box.add_child(squad_hp_lbl)
	inspector_squad_box.add_child(s_hp_box)

	squad_chips_box = HBoxContainer.new()
	squad_chips_box.add_theme_constant_override("separation", 8)
	inspector_squad_box.add_child(squad_chips_box)

# ─────────────────────────────────────────────────────────────────────────────
# 5. FLOATING BOTTOM-RIGHT COLLAPSIBLE BUILD DRAWER
# ─────────────────────────────────────────────────────────────────────────────
func build_floating_builder() -> void:
	# Floating Toggle Button
	build_toggle_btn = Button.new()
	build_toggle_btn.anchor_right = 1.0
	build_toggle_btn.anchor_left = 1.0
	build_toggle_btn.anchor_top = 1.0
	build_toggle_btn.anchor_bottom = 1.0
	build_toggle_btn.offset_left = -160.0
	build_toggle_btn.offset_right = -12.0
	build_toggle_btn.offset_top = -46.0
	build_toggle_btn.offset_bottom = -12.0
	build_toggle_btn.custom_minimum_size = Vector2(148, 34)
	build_toggle_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	build_toggle_btn.add_theme_stylebox_override("normal", create_toy_button_style(Color(0.18, 0.22, 0.30, 0.95), Color(0.9, 0.75, 0.3)))
	build_toggle_btn.add_theme_stylebox_override("hover", create_toy_button_style(Color(0.24, 0.30, 0.40, 0.98), Color(1.0, 0.88, 0.4)))
	build_toggle_btn.pressed.connect(_toggle_build_drawer)

	var b_hbox = HBoxContainer.new()
	b_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	b_hbox.add_theme_constant_override("separation", 6)
	b_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build_toggle_btn.add_child(b_hbox)

	if ResourceLoader.exists(ICON_HAMMER_BUILD):
		var h_tr = TextureRect.new()
		h_tr.texture = load(ICON_HAMMER_BUILD)
		h_tr.custom_minimum_size = Vector2(22, 22)
		h_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h_tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		h_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b_hbox.add_child(h_tr)

	var b_lbl = Label.new()
	b_lbl.text = "🔨 BUILD (8)"
	b_lbl.add_theme_font_size_override("font_size", 12)
	b_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	b_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b_hbox.add_child(b_lbl)
	add_child(build_toggle_btn)

	# Floating Build Drawer Panel (Pops above the button)
	build_drawer_panel = PanelContainer.new()
	build_drawer_panel.anchor_right = 1.0
	build_drawer_panel.anchor_left = 1.0
	build_drawer_panel.anchor_top = 1.0
	build_drawer_panel.anchor_bottom = 1.0
	build_drawer_panel.offset_left = -345.0
	build_drawer_panel.offset_right = -12.0
	build_drawer_panel.offset_top = -215.0
	build_drawer_panel.offset_bottom = -54.0
	build_drawer_panel.custom_minimum_size = Vector2(333, 161)

	var drawer_style = create_toy_panel_style(Color(0.08, 0.11, 0.16, 0.96), Color(0.75, 0.62, 0.28), 10, Vector4(8, 8, 6, 6))
	build_drawer_panel.add_theme_stylebox_override("panel", drawer_style)
	add_child(build_drawer_panel)

	var d_vbox = VBoxContainer.new()
	d_vbox.add_theme_constant_override("separation", 4)
	build_drawer_panel.add_child(d_vbox)

	var header_lbl = Label.new()
	header_lbl.text = "🏗️ ARCHIPELAGO CONSTRUCTION"
	header_lbl.add_theme_font_size_override("font_size", 11)
	header_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	d_vbox.add_child(header_lbl)

	build_grid = GridContainer.new()
	build_grid.columns = 4
	build_grid.add_theme_constant_override("h_separation", 5)
	build_grid.add_theme_constant_override("v_separation", 4)
	d_vbox.add_child(build_grid)

	populate_build_grid()

func _toggle_build_drawer() -> void:
	is_build_drawer_open = not is_build_drawer_open
	build_drawer_panel.visible = is_build_drawer_open

func populate_build_grid() -> void:
	for child in build_grid.get_children():
		child.queue_free()

	for b_key in building_catalog.keys():
		var data = building_catalog[b_key]
		var btn = create_blueprint_card(b_key, data["name"], data["cost_str"], data["cost"], data["icon"], data["desc"])
		build_grid.add_child(btn)

func create_blueprint_card(b_key: String, title: String, cost_str: String, cost_dict: Dictionary, icon_path: String, desc: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(75, 52)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var affordable = true
	if GameManager.instance:
		affordable = GameManager.instance.can_afford(cost_dict)

	var bg_col = Color(0.14, 0.18, 0.25, 0.95) if affordable else Color(0.10, 0.12, 0.15, 0.75)
	var border_col = Color(0.4, 0.5, 0.6) if affordable else Color(0.25, 0.28, 0.32)
	btn.add_theme_stylebox_override("normal", create_toy_button_style(bg_col, border_col))
	btn.add_theme_stylebox_override("hover", create_toy_button_style(Color(0.20, 0.28, 0.38, 0.98), Color(0.8, 0.7, 0.3)))

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	if ResourceLoader.exists(icon_path):
		var tr = TextureRect.new()
		tr.texture = load(icon_path)
		tr.custom_minimum_size = Vector2(24, 24)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not affordable:
			tr.modulate = Color(0.65, 0.65, 0.65, 0.7)
		vbox.add_child(tr)

	var name_lbl = Label.new()
	name_lbl.text = title
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	var cost_lbl = Label.new()
	cost_lbl.text = cost_str
	cost_lbl.add_theme_font_size_override("font_size", 8)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if affordable else Color(0.95, 0.45, 0.45))
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_lbl)

	btn.pressed.connect(func(): emit_signal("build_requested", b_key))
	btn.mouse_entered.connect(func(): show_tooltip(title, desc, cost_str, btn.global_position + Vector2(-120, -75)))
	btn.mouse_exited.connect(hide_tooltip)
	return btn

# ─────────────────────────────────────────────────────────────────────────────
# 6. INTERACTIVE TOOLTIP & NOTIFICATION BANNER
# ─────────────────────────────────────────────────────────────────────────────
func build_tooltip_ui() -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.custom_minimum_size = Vector2(190, 72)
	var t_style = create_toy_panel_style(Color(0.08, 0.10, 0.15, 0.98), Color(0.85, 0.72, 0.3), 8, Vector4(8, 8, 6, 6))
	tooltip_panel.add_theme_stylebox_override("panel", t_style)
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tooltip_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	tooltip_panel.add_child(vbox)

	tooltip_title = Label.new()
	tooltip_title.text = "Item"
	tooltip_title.add_theme_font_size_override("font_size", 11)
	tooltip_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	vbox.add_child(tooltip_title)

	tooltip_desc = Label.new()
	tooltip_desc.text = "Description"
	tooltip_desc.add_theme_font_size_override("font_size", 9)
	tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(tooltip_desc)

	tooltip_cost = Label.new()
	tooltip_cost.text = "Cost"
	tooltip_cost.add_theme_font_size_override("font_size", 9)
	tooltip_cost.add_theme_color_override("font_color", Color(0.7, 0.95, 0.45))
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
	notif_banner.offset_left = -260.0
	notif_banner.offset_top = 68.0
	notif_banner.offset_right = 260.0
	notif_banner.offset_bottom = 110.0

	var n_style = create_toy_panel_style(Color(0.22, 0.08, 0.08, 0.96), Color(0.95, 0.35, 0.25), 10, Vector4(12, 12, 6, 6))
	notif_banner.add_theme_stylebox_override("panel", n_style)
	notif_banner.visible = false
	add_child(notif_banner)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	notif_banner.add_child(hbox)

	if ResourceLoader.exists(ICON_RAID_WARNING):
		notif_icon = TextureRect.new()
		notif_icon.texture = load(ICON_RAID_WARNING)
		notif_icon.custom_minimum_size = Vector2(28, 28)
		notif_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		notif_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		notif_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hbox.add_child(notif_icon)

	notif_label = Label.new()
	notif_label.text = "Alert Banner"
	notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notif_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notif_label.add_theme_font_size_override("font_size", 13)
	notif_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.5))
	hbox.add_child(notif_label)

func show_notification(msg: String) -> void:
	notif_label.text = msg
	notif_banner.visible = true
	notif_timer = 5.0

func build_game_over_modal() -> void:
	game_over_modal = PanelContainer.new()
	game_over_modal.anchor_left = 0.5
	game_over_modal.anchor_top = 0.5
	game_over_modal.anchor_right = 0.5
	game_over_modal.anchor_bottom = 0.5
	game_over_modal.offset_left = -200.0
	game_over_modal.offset_top = -110.0
	game_over_modal.offset_right = 200.0
	game_over_modal.offset_bottom = 110.0
	game_over_modal.visible = false

	var style = create_toy_panel_style(Color(0.08, 0.11, 0.16, 0.98), Color(0.95, 0.8, 0.25), 14, Vector4(20, 20, 16, 16))
	game_over_modal.add_theme_stylebox_override("panel", style)
	add_child(game_over_modal)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_modal.add_child(vbox)

	game_over_title = Label.new()
	game_over_title.text = "VICTORY"
	game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(game_over_title)

	game_over_sub = Label.new()
	game_over_sub.text = "You conquered the archipelago!"
	game_over_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_sub.add_theme_font_size_override("font_size", 12)
	vbox.add_child(game_over_sub)

	var play_again_btn = Button.new()
	play_again_btn.text = "Play Again"
	play_again_btn.custom_minimum_size = Vector2(130, 34)
	play_again_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_again_btn.add_theme_stylebox_override("normal", create_toy_button_style(Color(0.2, 0.28, 0.38, 0.95), Color(0.85, 0.75, 0.3)))
	play_again_btn.pressed.connect(func(): get_tree().reload_current_scene())
	vbox.add_child(play_again_btn)

# ─────────────────────────────────────────────────────────────────────────────
# 7. EVENT LOOP & PROCESS
# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if notif_timer > 0.0:
		notif_timer -= delta
		if notif_timer <= 0.0:
			notif_banner.visible = false

	idle_update_timer += delta
	if idle_update_timer >= 0.3:
		idle_update_timer = 0.0
		update_idle_villagers_display()

	# Real-time training progress
	if is_instance_valid(current_inspected_building) and current_inspected_building.training_queue.size() > 0:
		training_progress_box.visible = true
		var t_type = current_inspected_building.training_queue[0]
		var ratio = clamp(current_inspected_building.training_timer / current_inspected_building.training_time_required, 0.0, 1.0)
		training_progress_bar.value = ratio * 100.0
		training_progress_lbl.text = "⚙️ Training %s: %d%% (%d queued)" % [t_type.capitalize(), int(ratio * 100.0), current_inspected_building.training_queue.size()]
	elif training_progress_box:
		training_progress_box.visible = false

func update_idle_villagers_display() -> void:
	var idle_count = get_idle_villagers().size()
	if idle_villager_lbl:
		idle_villager_lbl.text = "Idle: %d" % idle_count
		if idle_count > 0:
			idle_villager_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			idle_villager_btn.modulate = Color(0.7, 0.7, 0.7, 0.85)

func get_idle_villagers() -> Array:
	var idles = []
	if not is_inside_tree() or get_tree() == null:
		return idles
	var player_units = get_tree().get_nodes_in_group("player_units")
	for u in player_units:
		if is_instance_valid(u) and u is Villager and u.team == "player" and u.state == UnitBase.State.IDLE:
			idles.append(u)
	return idles

func _on_idle_villager_clicked() -> void:
	var idles = get_idle_villagers()
	if idles.is_empty():
		if GameManager.instance:
			GameManager.instance.post_notification("All villagers are actively working!")
		return

	last_idle_villager_index = (last_idle_villager_index + 1) % idles.size()
	var selected_v = idles[last_idle_villager_index]
	if is_instance_valid(selected_v):
		if GameManager.instance:
			GameManager.instance.select_entity(selected_v)
		emit_signal("minimap_clicked", selected_v.global_position)

# ─────────────────────────────────────────────────────────────────────────────
# 8. GAME MANAGER EVENT HANDLERS
# ─────────────────────────────────────────────────────────────────────────────
func _on_resources_changed(res: Dictionary) -> void:
	if food_label: food_label.text = str(res.get("food", 0))
	if wood_label: wood_label.text = str(res.get("wood", 0))
	if stone_label: stone_label.text = str(res.get("stone", 0))
	if gold_label: gold_label.text = str(res.get("gold", 0))
	var pop = res.get("population", 0)
	var max_pop = res.get("max_population", 10)
	if pop_label: pop_label.text = "👥 %d/%d" % [pop, max_pop]

	update_age_advancement_state()
	if is_build_drawer_open:
		populate_build_grid()

func update_age_advancement_state() -> void:
	if not GameManager.instance or not age_button:
		return

	var cur = GameManager.instance.current_age
	var cur_name = GameManager.instance.age_names[cur]
	era_badge_lbl.text = "🏛️ " + cur_name + " (Era %d)" % [cur + 1]

	if cur >= GameManager.Age.MEDIEVAL_AGE:
		if age_button_lbl: age_button_lbl.text = "👑 " + cur_name + " (Apex)"
		age_button.disabled = true
	else:
		var next_name = GameManager.instance.age_names[cur + 1]
		var cost = GameManager.instance.get_next_age_cost()
		var cost_str = ""
		for k in cost.keys():
			cost_str += str(cost[k]) + k.left(1).to_upper() + " "
		if age_button_lbl: age_button_lbl.text = "Advance -> " + next_name + " (" + cost_str.strip_edges() + ")"
		var can_adv = GameManager.instance.can_advance_age()
		age_button.disabled = not can_adv
		if can_adv:
			age_button.modulate = Color(1.15, 1.15, 1.0, 1.0)
		else:
			age_button.modulate = Color(0.85, 0.85, 0.85, 0.9)

func _on_age_advanced(_new_age: String) -> void:
	update_age_advancement_state()

func _on_age_button_pressed() -> void:
	emit_signal("age_advance_requested")

func _on_game_state_changed(state: String) -> void:
	game_over_modal.visible = true
	if state == "victory":
		game_over_title.text = "👑 ARCHIPELAGO CONQUERED!"
		game_over_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
		game_over_sub.text = "The enemy totem has fallen. Your island empire reigns supreme!"
	else:
		game_over_title.text = "💀 DEFEAT!"
		game_over_title.add_theme_color_override("font_color", Color(0.95, 0.25, 0.25))
		game_over_sub.text = "Your Town Center was destroyed by the raiders."

func _on_minimap_clicked(world_target: Vector3) -> void:
	emit_signal("minimap_clicked", world_target)

# ─────────────────────────────────────────────────────────────────────────────
# 9. CONTEXTUAL SELECTION INSPECTOR (SINGLE & SQUAD SUPPORT)
# ─────────────────────────────────────────────────────────────────────────────
func _on_selection_changed(entities: Array) -> void:
	current_selected_entities = entities
	current_inspected_building = null
	for child in dossier_actions_grid.get_children():
		child.queue_free()
	for child in squad_chips_box.get_children():
		child.queue_free()

	if entities.is_empty():
		inspector_empty_box.visible = true
		inspector_single_box.visible = false
		inspector_squad_box.visible = false
		return

	if entities.size() == 1:
		# Single Entity Selected
		inspector_empty_box.visible = false
		inspector_single_box.visible = true
		inspector_squad_box.visible = false
		setup_single_dossier(entities[0])
	else:
		# Multiple Units Selected (Squad Support)
		inspector_empty_box.visible = false
		inspector_single_box.visible = false
		inspector_squad_box.visible = true
		setup_squad_dossier(entities)

func setup_single_dossier(first: Node3D) -> void:
	if first is BuildingBase:
		var b: BuildingBase = first
		current_inspected_building = b
		dossier_name.text = b.building_type.replace("_", " ").capitalize()
		dossier_type_badge.text = "[" + b.team.capitalize() + " Structure]"
		dossier_hp_bar.max_value = b.max_hp
		dossier_hp_bar.value = b.current_hp
		dossier_hp_text.text = "%d / %d HP" % [b.current_hp, b.max_hp]
		dossier_stats.text = "Structural Integrity: %d%%" % [int(float(b.current_hp) / float(b.max_hp) * 100)]

		var icon_path = "res://assets/ui/icon_" + b.building_type + ".png"
		if ResourceLoader.exists(icon_path):
			dossier_avatar.texture = load(icon_path)

		if b.team == "player":
			setup_building_production_grid(b)

	elif first is RoyalKnight:
		var rk: RoyalKnight = first
		dossier_name.text = "Royal Knight"
		dossier_type_badge.text = "[Heavy Cavalry]"
		dossier_hp_bar.max_value = rk.max_hp
		dossier_hp_bar.value = rk.current_hp
		dossier_hp_text.text = "%d / %d HP" % [rk.current_hp, rk.max_hp]
		dossier_stats.text = "⚔️ Lance: 32 Dmg | 🏃 Speed: 8.5 | 🛡️ Heavy Armor"
		if ResourceLoader.exists("res://assets/characters/royal_knight.png"):
			dossier_avatar.texture = load("res://assets/characters/royal_knight.png")

	elif first is HeroCommander:
		var hero: HeroCommander = first
		dossier_name.text = "Island Lord"
		dossier_type_badge.text = "[Supreme Commander]"
		dossier_hp_bar.max_value = hero.max_hp
		dossier_hp_bar.value = hero.current_hp
		dossier_hp_text.text = "%d / %d HP" % [hero.current_hp, hero.max_hp]
		dossier_stats.text = "⚔️ Broadsword: 28 Dmg | 👑 Inspiring Aura (12m)"
		if ResourceLoader.exists("res://assets/ui/island_lord.png"):
			dossier_avatar.texture = load("res://assets/ui/island_lord.png")

	elif first is Catapult:
		var cat: Catapult = first
		dossier_name.text = "Siege Catapult"
		dossier_type_badge.text = "[Siege Engine]"
		dossier_hp_bar.max_value = cat.max_hp
		dossier_hp_bar.value = cat.current_hp
		dossier_hp_text.text = "%d / %d HP" % [cat.current_hp, cat.max_hp]
		dossier_stats.text = "💥 Siege Boulder: 45 Dmg (24m Range) | 🏃 Speed: 3.4"
		if ResourceLoader.exists("res://assets/ui/icon_catapult_workshop.png"):
			dossier_avatar.texture = load("res://assets/ui/icon_catapult_workshop.png")

	elif first is WarGalleon:
		var wg: WarGalleon = first
		dossier_name.text = "War Galleon"
		dossier_type_badge.text = "[Artillery Warship]"
		dossier_hp_bar.max_value = wg.max_hp
		dossier_hp_bar.value = wg.current_hp
		dossier_hp_text.text = "%d / %d HP" % [wg.current_hp, wg.max_hp]
		dossier_stats.text = "💣 Broadside Cannons: 35 Dmg | ⚓ Heavy Warship"
		if ResourceLoader.exists("res://assets/ui/icon_harbor.png"):
			dossier_avatar.texture = load("res://assets/ui/icon_harbor.png")

	elif first is TransportShip:
		var ship: TransportShip = first
		dossier_name.text = "Galley Transport"
		dossier_type_badge.text = "[Amphibious Fleet]"
		dossier_hp_bar.max_value = ship.max_hp
		dossier_hp_bar.value = ship.current_hp
		dossier_hp_text.text = "%d / %d HP" % [ship.current_hp, ship.max_hp]
		dossier_stats.text = "Troops Embarked: %d / %d" % [ship.embarked_units.size(), ship.max_capacity]
		if ResourceLoader.exists("res://assets/ui/icon_harbor.png"):
			dossier_avatar.texture = load("res://assets/ui/icon_harbor.png")

		var disembark_btn = Button.new()
		disembark_btn.text = "⛵ Disembark Troops"
		disembark_btn.custom_minimum_size = Vector2(130, 28)
		disembark_btn.add_theme_font_size_override("font_size", 10)
		disembark_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		disembark_btn.add_theme_stylebox_override("normal", create_toy_button_style(Color(0.18, 0.25, 0.35, 0.95), Color(0.85, 0.72, 0.3)))
		disembark_btn.pressed.connect(func(): ship.disembark_all(ship.global_position))
		dossier_actions_grid.add_child(disembark_btn)

	elif first is Villager:
		var v: Villager = first
		dossier_name.text = "Villager"
		dossier_type_badge.text = "[Laborer]"
		dossier_hp_bar.max_value = v.max_hp
		dossier_hp_bar.value = v.current_hp
		dossier_hp_text.text = "%d / %d HP" % [v.current_hp, v.max_hp]
		var cargo = "None" if v.carried_amount == 0 else "%d %s" % [v.carried_amount, v.carried_type.capitalize()]
		dossier_stats.text = "🎒 Cargo: %s | 🏃 Speed: %.1f | Status: %s" % [cargo, v.move_speed, UnitBase.State.keys()[v.state]]
		if ResourceLoader.exists(ICON_IDLE_VILLAGER):
			dossier_avatar.texture = load(ICON_IDLE_VILLAGER)

	elif first is UnitBase:
		var u: UnitBase = first
		dossier_name.text = u.unit_name
		dossier_type_badge.text = "[" + u.team.capitalize() + "]"
		dossier_hp_bar.max_value = u.max_hp
		dossier_hp_bar.value = u.current_hp
		dossier_hp_text.text = "%d / %d HP" % [u.current_hp, u.max_hp]
		dossier_stats.text = "⚔️ Attack: %d | 🏃 Speed: %.1f | Range: %.1fm" % [u.attack_damage, u.move_speed, u.attack_range]
		if ResourceLoader.exists("res://assets/ui/icon_barracks.png"):
			dossier_avatar.texture = load("res://assets/ui/icon_barracks.png")

func setup_building_production_grid(b: BuildingBase) -> void:
	match b.building_type:
		"town_center":
			add_training_card("villager", "Villager", "50F", "res://assets/ui/icon_food.png", "Harvests resources and constructs buildings.", b)
			add_training_card("hero_commander", "Island Lord", "150F, 150G", "res://assets/ui/island_lord.png", "Supreme commander with Inspiring Aura.", b)
		"barracks":
			add_training_card("spearman", "Spearman", "60F, 30W", ICON_SQUAD_SPEARMAN, "Line infantry, strong defense.", b)
			add_training_card("archer", "Archer", "50F, 50W", ICON_SQUAD_ARCHER, "Ranged marksman.", b)
			add_training_card("knight", "Royal Knight", "100F, 80G", ICON_SQUAD_KNIGHT, "Fast heavy cavalry shock unit.", b)
		"harbor":
			add_training_card("transport_ship", "Galley", "120W, 40G", "res://assets/ui/icon_harbor.png", "Naval transport for amphibious troops.", b)
			add_training_card("war_galleon", "War Galleon", "220W, 80S, 100G", "res://assets/ui/icon_harbor.png", "Armed warship with broadside cannons.", b)
		"catapult_workshop":
			add_training_card("catapult", "Catapult", "150W, 100S, 50G", "res://assets/ui/icon_catapult_workshop.png", "Heavy siege weapon that hurls boulders.", b)

func add_training_card(type: String, title: String, cost: String, icon_path: String, desc: String, b: BuildingBase) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(105, 38)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", create_toy_button_style(Color(0.14, 0.20, 0.28, 0.95), Color(0.4, 0.55, 0.7)))
	btn.add_theme_stylebox_override("hover", create_toy_button_style(Color(0.20, 0.28, 0.38, 0.98), Color(0.9, 0.8, 0.3)))

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	if ResourceLoader.exists(icon_path):
		var tr = TextureRect.new()
		tr.texture = load(icon_path)
		tr.custom_minimum_size = Vector2(22, 22)
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
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	var cost_lbl = Label.new()
	cost_lbl.text = cost
	cost_lbl.add_theme_font_size_override("font_size", 8)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(cost_lbl)
	hbox.add_child(vbox)

	btn.pressed.connect(func(): emit_signal("train_unit_requested", type, b))
	btn.mouse_entered.connect(func(): show_tooltip("Train " + title, desc, cost, btn.global_position + Vector2(0, -75)))
	btn.mouse_exited.connect(hide_tooltip)
	dossier_actions_grid.add_child(btn)

func setup_squad_dossier(entities: Array) -> void:
	squad_title_lbl.text = "⚔️ TACTICAL SQUAD (%d Units Selected)" % entities.size()

	var total_hp = 0
	var total_max_hp = 0
	var type_counts = {}

	for e in entities:
		if is_instance_valid(e) and e is UnitBase:
			var u: UnitBase = e
			total_hp += u.current_hp
			total_max_hp += u.max_hp
			var key = u.unit_name
			type_counts[key] = type_counts.get(key, 0) + 1

	squad_hp_bar.max_value = max(total_max_hp, 1)
	squad_hp_bar.value = total_hp
	var pct = int((float(total_hp) / float(max(total_max_hp, 1))) * 100.0)
	squad_hp_lbl.text = "%d / %d HP (%d%%)" % [total_hp, total_max_hp, pct]

	for type_name in type_counts.keys():
		var count = type_counts[type_name]
		var icon_path = ""
		match type_name.to_lower():
			"spearman": icon_path = ICON_SQUAD_SPEARMAN
			"archer": icon_path = ICON_SQUAD_ARCHER
			"royal knight": icon_path = ICON_SQUAD_KNIGHT
			"villager": icon_path = ICON_IDLE_VILLAGER
			_: icon_path = "res://assets/ui/icon_barracks.png"

		var chip = create_squad_chip(type_name, count, icon_path)
		squad_chips_box.add_child(chip)

func create_squad_chip(type_name: String, count: int, icon_path: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(90, 32)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", create_toy_button_style(Color(0.12, 0.16, 0.22, 0.92), Color(0.45, 0.55, 0.65)))
	btn.add_theme_stylebox_override("hover", create_toy_button_style(Color(0.18, 0.24, 0.32, 0.95), Color(0.9, 0.8, 0.3)))

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	if ResourceLoader.exists(icon_path):
		var tr = TextureRect.new()
		tr.texture = load(icon_path)
		tr.custom_minimum_size = Vector2(20, 20)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(tr)

	var lbl = Label.new()
	lbl.text = "%s x%d" % [type_name, count]
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lbl)

	# Click chip to filter selection to only this unit type
	btn.pressed.connect(func():
		var filtered = []
		for e in current_selected_entities:
			if is_instance_valid(e) and e is UnitBase and e.unit_name == type_name:
				filtered.append(e)
		if GameManager.instance and filtered.size() > 0:
			GameManager.instance.set_selection_group(filtered)
	)
	return btn

func _on_squad_halt_clicked() -> void:
	for e in current_selected_entities:
		if is_instance_valid(e) and e is UnitBase:
			var u: UnitBase = e
			u.command_stop()
	if GameManager.instance:
		GameManager.instance.post_notification("Squad halt command issued.")
