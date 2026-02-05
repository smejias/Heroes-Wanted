extends Node

var hex_grid: HexGrid
var resource_manager: Node
var time_manager: Node

var states: Dictionary = {}
var current_state: GameState
var current_state_name: String = ""


func _ready() -> void:
	_setup_states()
	
	EventBus.construction_completed.connect(_on_construction_completed)


func _setup_states() -> void:
	var play_state = PlayState.new()
	play_state.game_manager = self
	states["play"] = play_state
	
	var build_state = BuildState.new()
	build_state.game_manager = self
	states["build"] = build_state
	
	change_state("play")


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
		
	if event.is_action_pressed("speed_up"):
		TimeManager.cycle_speed()


func change_state(state_name: String) -> void:
	current_state_name = state_name
	if current_state:
		current_state.exit()
	
	current_state = states.get(state_name)
	if current_state:
		current_state.enter()


func get_current_state_name() -> String:
	for name in states.keys():
		if states[name] == current_state:
			return name
	return ""


func register_hex_grid(grid: HexGrid) -> void:
	hex_grid = grid


func register_resource_manager(manager: Node) -> void:
	resource_manager = manager


func register_time_manager(manager: Node) -> void:
	time_manager = manager


func _on_construction_completed(tile: Tile, district_data: DistrictData) -> void:
	# Refresh buildable area when new district is built
	if current_state is BuildState:
		current_state._refresh_buildable_tiles()
