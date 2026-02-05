class_name BuildState
extends GameState

enum Phase { SELECT_DISTRICT, SELECT_TILE, CONFIRM }

var phase: Phase = Phase.SELECT_DISTRICT
var selected_district: DistrictData = null
var selected_tile: Tile = null
var buildable_tiles: Array[Tile] = []
var _confirmation_popup: Control = null


func enter() -> void:
	phase = Phase.SELECT_DISTRICT
	selected_district = null
	selected_tile = null
	
	EventBus.build_mode_entered.emit()
	EventBus.district_selected.connect(_on_district_selected)
	
	# Debug
	print("Looking for popup...")
	_confirmation_popup = game_manager.get_tree().get_first_node_in_group("build_confirmation_popup")
	print("Found popup: ", _confirmation_popup)
	
	if _confirmation_popup:
		_confirmation_popup.confirmed.connect(_on_build_confirmed)
		_confirmation_popup.cancelled.connect(_on_build_cancelled)


func exit() -> void:
	_clear_highlights()
	
	if EventBus.district_selected.is_connected(_on_district_selected):
		EventBus.district_selected.disconnect(_on_district_selected)
	
	if _confirmation_popup:
		if _confirmation_popup.confirmed.is_connected(_on_build_confirmed):
			_confirmation_popup.confirmed.disconnect(_on_build_confirmed)
		if _confirmation_popup.cancelled.is_connected(_on_build_cancelled):
			_confirmation_popup.cancelled.disconnect(_on_build_cancelled)
		_confirmation_popup.visible = false
	
	EventBus.build_mode_exited.emit()


func _on_district_selected(district: DistrictData) -> void:
	selected_district = district
	phase = Phase.SELECT_TILE
	_refresh_buildable_tiles()
	_highlight_valid_tiles()


func _refresh_buildable_tiles() -> void:
	buildable_tiles.clear()
	
	if not game_manager.hex_grid or not selected_district:
		return
	
	var all_buildable = game_manager.hex_grid.get_buildable_tiles()
	
	for tile in all_buildable:
		if selected_district.can_build_on_terrain(tile.terrain_type):
			buildable_tiles.append(tile)


func _highlight_valid_tiles() -> void:
	_clear_highlights()
	
	if not selected_district:
		return
	
	for tile in buildable_tiles:
		tile.highlight(true)


func _clear_highlights() -> void:
	if game_manager.hex_grid:
		game_manager.hex_grid.clear_all_highlights()


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_mode"):
		game_manager.change_state("play")
		return
	
	if event.is_action_pressed("cancel"):
		_handle_cancel()
		return
	
	if phase == Phase.SELECT_TILE:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_try_select_tile()


func _handle_cancel() -> void:
	match phase:
		Phase.SELECT_DISTRICT:
			game_manager.change_state("play")
		Phase.SELECT_TILE:
			selected_district = null
			_clear_highlights()
			phase = Phase.SELECT_DISTRICT
		Phase.CONFIRM:
			selected_tile = null
			_highlight_valid_tiles()
			phase = Phase.SELECT_TILE


func _try_select_tile() -> void:
	if not selected_district:
		return
	
	if not ResourceManager.can_afford(selected_district):
		_reset_to_district_selection()
		return
	
	var tile = _get_tile_under_mouse()
	if not tile:
		return
	
	if not tile in buildable_tiles:
		return
	
	selected_tile = tile
	phase = Phase.CONFIRM
	_clear_highlights()
	tile.highlight(true)
	
	if _confirmation_popup:
		_confirmation_popup.show_confirmation(selected_district, selected_tile)


func _on_build_confirmed() -> void:
	if not selected_district or not selected_tile:
		return
	
	if not ResourceManager.can_afford(selected_district):
		_reset_to_district_selection()
		return
	
	ResourceManager.spend(selected_district)
	selected_tile.start_construction(selected_district)
	
	selected_tile = null
	
	if ResourceManager.can_afford(selected_district):
		phase = Phase.SELECT_TILE
		_refresh_buildable_tiles()
		_highlight_valid_tiles()
	else:
		_reset_to_district_selection()


func _reset_to_district_selection() -> void:
	selected_district = null
	selected_tile = null
	_clear_highlights()
	phase = Phase.SELECT_DISTRICT


func _on_build_cancelled() -> void:
	selected_tile = null
	phase = Phase.SELECT_TILE
	_highlight_valid_tiles()


func _get_tile_under_mouse() -> Tile:
	var viewport = game_manager.get_viewport()
	var camera = viewport.get_camera_3d()
	if not camera:
		return null
	
	var mouse_pos = viewport.get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	
	var world = camera.get_world_3d()
	var space_state = world.direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		var parent = result.collider.get_parent()
		if parent is Tile:
			return parent
	
	return null
