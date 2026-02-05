class_name DistrictData
extends Resource

@export var id: StringName
@export var display_name: String
@export var description: String
@export var type: GameEnums.DistrictType
@export var scene: PackedScene
@export var icon: Texture2D

@export_group("Construction")
@export var build_radius: int = 2
@export var construction_time: float = 10.0
@export var gold_cost: int = 0
@export var food_cost: int = 0
@export var materials_cost: int = 0

@export_group("Work Schedule")
@export var work_start_hour: int = 8
@export var work_end_hour: int = 18
@export var production_interval_hours: float = 1.0

@export_group("Daily Production")
@export var gold_production: int = 0
@export var food_production: int = 0
@export var materials_production: int = 0

@export_group("Housing")
@export var housing_capacity: int = 0

@export_group("Daily Consumption")
@export var gold_consumption: int = 0
@export var food_consumption: int = 0
@export var materials_consumption: int = 0

@export_group("Quests")
@export var possible_quests: Array[QuestData] = []
@export var quest_spawn_chance: float = 0.3

@export_group("Appeal & Parties")
@export var appeal_bonus: int = 0
@export var max_parties_bonus: int = 0
@export var stay_duration_bonus: int = 0

@export_group("Requirements")
@export var required_terrain: GameEnums.TerrainType = GameEnums.TerrainType.GRASSLAND
@export var has_terrain_requirement: bool = false


func get_work_hours() -> int:
	if work_start_hour < work_end_hour:
		return work_end_hour - work_start_hour
	else:
		return (24 - work_start_hour) + work_end_hour


func get_ticks_per_day() -> int:
	return int(get_work_hours() / production_interval_hours)


func get_production_per_tick() -> Dictionary:
	var ticks = get_ticks_per_day()
	return {
		"gold": gold_production / float(ticks),
		"food": food_production / float(ticks),
		"materials": materials_production / float(ticks)
	}


func get_consumption_per_tick() -> Dictionary:
	var ticks = get_ticks_per_day()
	return {
		"gold": gold_consumption / float(ticks),
		"food": food_consumption / float(ticks),
		"materials": materials_consumption / float(ticks)
	}


func is_working_hour(hour: float) -> bool:
	return hour >= work_start_hour and hour < work_end_hour
	
func can_build_on_terrain(terrain: GameEnums.TerrainType) -> bool:
	if not has_terrain_requirement:
		return true
	return terrain == required_terrain	
