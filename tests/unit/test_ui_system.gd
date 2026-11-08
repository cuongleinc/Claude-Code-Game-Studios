class_name TestUISystem
extends RefCounted

var gm: GameManager
var hud: RTSHud

func setup() -> void:
	gm = GameManager.new()
	GameManager.instance = gm
	gm._ready()

	hud = RTSHud.new()
	hud._ready()

func teardown() -> void:
	if is_instance_valid(hud):
		hud.free()
	if is_instance_valid(gm):
		gm.free()
		GameManager.instance = null

func assert_true(condition: bool, msg: String = "") -> Dictionary:
	if not condition:
		return {"passed": false, "message": msg}
	return {"passed": true}

func assert_eq(a, b, msg: String = "") -> Dictionary:
	if a != b:
		return {"passed": false, "message": "Expected %s but got %s. %s" % [str(b), str(a), msg]}
	return {"passed": true}

func test_hud_initializes_floating_panels() -> Dictionary:
	if not hud.radar_container:
		return {"passed": false, "message": "Floating radar container should be initialized"}
	if not hud.inspector_capsule:
		return {"passed": false, "message": "Floating contextual inspector capsule should be initialized"}
	if not hud.build_drawer_panel:
		return {"passed": false, "message": "Floating build drawer panel should be initialized"}
	if not hud.build_toggle_btn:
		return {"passed": false, "message": "Build drawer toggle button should be initialized"}
	return {"passed": true}

func test_building_catalog_completeness() -> Dictionary:
	var keys = hud.building_catalog.keys()
	if keys.size() != 8:
		return {"passed": false, "message": "Expected 8 buildings in catalog, got %d" % keys.size()}
	if not hud.building_catalog.has("house") or not hud.building_catalog.has("barracks") or not hud.building_catalog.has("harbor"):
		return {"passed": false, "message": "Catalog missing core buildings"}
	return {"passed": true}

func test_build_drawer_toggle() -> Dictionary:
	var initial_state = hud.is_build_drawer_open
	hud._toggle_build_drawer()
	if hud.is_build_drawer_open == initial_state:
		return {"passed": false, "message": "Build drawer toggle should flip open state"}
	hud._toggle_build_drawer()
	return assert_eq(hud.is_build_drawer_open, initial_state, "Toggling again should restore state")

func test_minimap_radar_world_to_map() -> Dictionary:
	var radar = MinimapRadar.new()
	radar.size = Vector2(175, 145)
	var map_pos = radar.world_to_map(Vector3(-50.0, 0.0, 0.0))
	if map_pos.x <= 0 or map_pos.x >= radar.size.x or map_pos.y <= 0 or map_pos.y >= radar.size.y:
		return {"passed": false, "message": "Player island center should map inside radar bounds"}
	radar.free()
	return {"passed": true}

func test_single_selection_dossier_activation() -> Dictionary:
	var tc = BuildingBase.new()
	tc.setup("town_center", Vector3.ZERO, "player", true)
	hud._on_selection_changed([tc])

	if not hud.inspector_single_box.visible:
		tc.free()
		return {"passed": false, "message": "Single selection box should be visible when one entity is selected"}
	if hud.inspector_empty_box.visible:
		tc.free()
		return {"passed": false, "message": "Empty selection box should be hidden when entity is selected"}

	tc.free()
	return {"passed": true}

func test_squad_multi_selection_activation() -> Dictionary:
	var u1 = UnitBase.new()
	u1.unit_name = "Spearman"
	var u2 = UnitBase.new()
	u2.unit_name = "Archer"

	hud._on_selection_changed([u1, u2])

	if not hud.inspector_squad_box.visible:
		u1.free()
		u2.free()
		return {"passed": false, "message": "Squad selection box should be visible when multiple units are selected"}
	if hud.inspector_single_box.visible:
		u1.free()
		u2.free()
		return {"passed": false, "message": "Single dossier box should be hidden during squad selection"}

	u1.free()
	u2.free()
	return {"passed": true}
