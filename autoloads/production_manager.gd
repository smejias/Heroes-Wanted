extends Node

var _production_accumulator: Dictionary = {}
var _consumption_accumulator: Dictionary = {}
var _last_tick_hour: float = -1.0
var _paused_districts: Dictionary = {}


func _ready() -> void:
	EventBus.hour_changed.connect(_on_hour_changed)
	EventBus.construction_completed.connect(_on_construction_completed)


func _on_construction_completed(tile: Tile, _data: DistrictData) -> void:
	_production_accumulator[tile] = {"gold": 0.0, "food": 0.0, "materials": 0.0}
	_consumption_accumulator[tile] = {"gold": 0.0, "food": 0.0, "materials": 0.0}
	_paused_districts[tile] = false


func _on_hour_changed(hour: float) -> void:
	var grid = GameManager.hex_grid
	if not grid:
		return
	
	for tile in grid.get_built_tiles():
		_process_tile(tile, hour)


func _process_tile(tile: Tile, hour: float) -> void:
	if tile.state != GameEnums.TileState.BUILT:
		return
	
	var data = tile.district_data
	if not data:
		return
	
	if not data.is_working_hour(hour):
		return
	
	if not _should_tick(tile, data, hour):
		return
	
	_process_consumption(tile, data)
	
	if not _paused_districts.get(tile, false):
		_process_production(tile, data)


func _should_tick(tile: Tile, data: DistrictData, hour: float) -> bool:
	var interval = data.production_interval_hours
	var work_start = data.work_start_hour
	var hours_since_start = hour - work_start
	
	return fmod(hours_since_start, interval) < 0.1


func _process_production(tile: Tile, data: DistrictData) -> void:
	var production = data.get_production_per_tick()
	
	if not _production_accumulator.has(tile):
		_production_accumulator[tile] = {"gold": 0.0, "food": 0.0, "materials": 0.0}
	
	_production_accumulator[tile]["gold"] += production["gold"]
	_production_accumulator[tile]["food"] += production["food"]
	_production_accumulator[tile]["materials"] += production["materials"]
	
	_flush_production(tile)


func _flush_production(tile: Tile) -> void:
	var acc = _production_accumulator[tile]
	
	if acc["gold"] >= 1.0:
		var amount = int(acc["gold"])
		ResourceManager.add(GameEnums.ResourceType.GOLD, amount)
		acc["gold"] -= amount
	
	if acc["food"] >= 1.0:
		var amount = int(acc["food"])
		ResourceManager.add(GameEnums.ResourceType.FOOD, amount)
		acc["food"] -= amount
	
	if acc["materials"] >= 1.0:
		var amount = int(acc["materials"])
		ResourceManager.add(GameEnums.ResourceType.MATERIALS, amount)
		acc["materials"] -= amount


func _process_consumption(tile: Tile, data: DistrictData) -> void:
	var consumption = data.get_consumption_per_tick()
	
	if consumption["gold"] <= 0 and consumption["food"] <= 0 and consumption["materials"] <= 0:
		return
	
	if not _consumption_accumulator.has(tile):
		_consumption_accumulator[tile] = {"gold": 0.0, "food": 0.0, "materials": 0.0}
	
	_consumption_accumulator[tile]["gold"] += consumption["gold"]
	_consumption_accumulator[tile]["food"] += consumption["food"]
	_consumption_accumulator[tile]["materials"] += consumption["materials"]
	
	_flush_consumption(tile)


func _flush_consumption(tile: Tile) -> void:
	var acc = _consumption_accumulator[tile]
	var was_paused = _paused_districts.get(tile, false)
	
	var gold_needed = int(acc["gold"]) if acc["gold"] >= 1.0 else 0
	var food_needed = int(acc["food"]) if acc["food"] >= 1.0 else 0
	var materials_needed = int(acc["materials"]) if acc["materials"] >= 1.0 else 0
	
	var can_afford = (
		ResourceManager.get_gold() >= gold_needed and
		ResourceManager.get_food() >= food_needed and
		ResourceManager.get_materials() >= materials_needed
	)
	
	if can_afford:
		if gold_needed > 0:
			ResourceManager.spend_type(GameEnums.ResourceType.GOLD, gold_needed)
			acc["gold"] -= gold_needed
		if food_needed > 0:
			ResourceManager.spend_type(GameEnums.ResourceType.FOOD, food_needed)
			acc["food"] -= food_needed
		if materials_needed > 0:
			ResourceManager.spend_type(GameEnums.ResourceType.MATERIALS, materials_needed)
			acc["materials"] -= materials_needed
		
		if was_paused:
			_paused_districts[tile] = false
			EventBus.district_resumed.emit(tile)
	else:
		if not was_paused:
			_paused_districts[tile] = true
			EventBus.district_paused.emit(tile)


func is_district_paused(tile: Tile) -> bool:
	return _paused_districts.get(tile, false)


func get_district_status(tile: Tile) -> String:
	if _paused_districts.get(tile, false):
		return "Paused (no resources)"
	
	var data = tile.district_data
	if not data:
		return "No data"
	
	var hour = TimeManager.get_hour()
	if data.is_working_hour(hour):
		return "Working"
	else:
		return "Off hours"
