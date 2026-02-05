extends Node3D

@export var starter_district: DistrictData
@export var starter_coord: Vector3i = Vector3i(0, 0, 0)

@onready var hex_grid: HexGrid = $HexGrid


func _ready() -> void:
	GameManager.register_hex_grid(hex_grid)
	
	await get_tree().process_frame
	
	_place_starter_district()


func _place_starter_district() -> void:
	if not starter_district:
		push_warning("No starter district assigned")
		return
	
	var tile = hex_grid.get_tile(starter_coord)
	if not tile:
		push_error("Invalid starter coord: " + str(starter_coord))
		return
	
	tile.district_data = starter_district
	tile.state = GameEnums.TileState.BUILT
	tile._spawn_district()
	
	EventBus.construction_completed.emit(tile, starter_district)
