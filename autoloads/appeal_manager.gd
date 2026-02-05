extends Node

var _appeal_breakdown: Dictionary = {}
var _starvation_hours: int = 0
var _recently_expired_quests: Array[Dictionary] = []


func _ready() -> void:
	EventBus.construction_completed.connect(_on_recalculate)
	EventBus.district_disabled.connect(_on_recalculate)
	EventBus.district_damaged.connect(_on_recalculate)
	EventBus.district_repaired.connect(_on_recalculate)
	EventBus.resources_changed.connect(_on_resources_changed)
	EventBus.population_changed.connect(_on_recalculate_any)
	EventBus.hour_changed.connect(_on_hour_changed)
	EventBus.day_started.connect(_on_day_started)
	EventBus.quest_expired.connect(_on_quest_expired)
	
	call_deferred("_recalculate")


func _on_recalculate(_arg1 = null, _arg2 = null) -> void:
	_recalculate()


func _on_recalculate_any(_arg1 = null, _arg2 = null) -> void:
	_recalculate()


func _on_resources_changed(type: int, amount: int) -> void:
	if type == GameEnums.ResourceType.FOOD:
		if amount > 0:
			_starvation_hours = 0
		_recalculate()


func _on_hour_changed(_hour: float) -> void:
	if ResourceManager.get_food() <= 0:
		_starvation_hours = min(_starvation_hours + 1, 24)  # Max 24 horas
	_recalculate()


func _on_day_started(day: int) -> void:
	_cleanup_expired_quests(day)
	_recalculate()


func _on_quest_expired(quest: Quest) -> void:
	_recently_expired_quests.append({
		"quest": quest,
		"day": TimeManager.get_day()
	})
	_recalculate()


func _cleanup_expired_quests(current_day: int) -> void:
	var config = _get_config()
	var duration = config.recently_expired_duration_days
	
	_recently_expired_quests = _recently_expired_quests.filter(func(entry):
		return current_day - entry["day"] < duration
	)


func _get_config() -> AppealConfig:
	return ConfigManager.config.appeal_config


func _recalculate() -> void:
	_appeal_breakdown.clear()
	
	var config = _get_config()
	if not config:
		push_error("AppealConfig not assigned in GameConfig")
		return
	
	# Base appeal
	_appeal_breakdown["Base"] = config.base_appeal
	
	# District bonuses
	_calculate_district_appeal()
	
	# Resource penalties
	_calculate_resource_penalties(config)
	
	# Population penalties
	_calculate_population_penalties(config)
	
	# Quest penalties
	_calculate_quest_penalties(config)
	
	EventBus.appeal_changed.emit(get_appeal(), _appeal_breakdown)


func _calculate_district_appeal() -> void:
	var grid = GameManager.hex_grid
	if not grid:
		return
	
	var district_bonus = 0
	var disabled_count = 0
	var damaged_count = 0
	
	for tile in grid.get_all_tiles():
		if tile.state == GameEnums.TileState.BUILT and tile.district_data:
			district_bonus += tile.district_data.appeal_bonus
		elif tile.state == GameEnums.TileState.DISABLED:
			disabled_count += 1
		elif tile.state == GameEnums.TileState.DAMAGED:
			damaged_count += 1
	
	if district_bonus != 0:
		_appeal_breakdown["Districts"] = district_bonus
	
	if disabled_count > 0:
		var config = _get_config()
		_appeal_breakdown["Disabled Districts"] = disabled_count * config.disabled_district_penalty
	
	if damaged_count > 0:
		var config = _get_config()
		_appeal_breakdown["Damaged Districts"] = damaged_count * config.damaged_district_penalty


func _calculate_resource_penalties(config: AppealConfig) -> void:
	if ResourceManager.get_food() <= 0:
		_appeal_breakdown["No Food"] = config.no_food_penalty
		
		if _starvation_hours > 0:
			_appeal_breakdown["Starvation"] = _starvation_hours * config.starvation_penalty_per_hour


func _calculate_population_penalties(config: AppealConfig) -> void:
	var population = PopulationManager.get_population()
	var max_pop = PopulationManager.get_max_population()
	
	if population > max_pop:
		_appeal_breakdown["Overcrowding"] = config.overcrowding_penalty


func _calculate_quest_penalties(config: AppealConfig) -> void:
	var dangerous_quests = 0
	for quest in QuestManager.active_quests:
		if quest.state == GameEnums.QuestState.ACTIVE:
			dangerous_quests += 1
	
	if dangerous_quests > 0:
		_appeal_breakdown["Active Threats"] = dangerous_quests * config.active_dangerous_quest_penalty
	
	if _recently_expired_quests.size() > 0:
		_appeal_breakdown["Recent Failures"] = _recently_expired_quests.size() * config.recently_expired_quest_penalty


func get_appeal() -> int:
	var total = 0
	for value in _appeal_breakdown.values():
		total += value
	return total


func get_breakdown() -> Dictionary:
	return _appeal_breakdown.duplicate()


func get_max_party_level() -> int:
	var thresholds = ConfigManager.config.appeal_level_thresholds
	var appeal = get_appeal()
	var max_level = 1
	
	for i in range(thresholds.size()):
		if appeal >= thresholds[i]:
			max_level = i + 1
	
	return max_level


func get_max_parties() -> int:
	var base = ConfigManager.config.base_max_parties
	
	var grid = GameManager.hex_grid
	if not grid:
		return base
	
	var bonus = 0
	for tile in grid.get_built_tiles():
		if tile.state == GameEnums.TileState.BUILT and tile.district_data:
			bonus += tile.district_data.max_parties_bonus
	
	return max(1, base + bonus)


func get_stay_duration() -> int:
	var base = ConfigManager.config.base_stay_duration
	
	var grid = GameManager.hex_grid
	if not grid:
		return base
	
	var bonus = 0
	for tile in grid.get_built_tiles():
		if tile.state == GameEnums.TileState.BUILT and tile.district_data:
			bonus += tile.district_data.stay_duration_bonus
	
	return base + bonus
