class_name PlayState
extends GameState

var _district_popup: Control = null


func enter() -> void:
	_district_popup = game_manager.get_tree().get_first_node_in_group("district_popup")


func exit() -> void:
	pass


func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_mode"):
		game_manager.change_state("build")
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_select_district()


func _try_select_district() -> void:
	var tile = _get_tile_under_mouse()
	if not tile:
		return
	
	if tile.state == GameEnums.TileState.BUILT or \
	   tile.state == GameEnums.TileState.DISABLED or \
	   tile.state == GameEnums.TileState.DAMAGED:
		if _district_popup:
			_district_popup.show_district(tile)


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
