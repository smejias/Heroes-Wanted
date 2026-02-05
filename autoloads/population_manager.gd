extends Node

var population: int = 0
var _food_consumption_accumulator: float = 0.0
var _last_overflow_check_hour: float = -1.0


func _ready() -> void:
	population = ConfigManager.config.starting_population
	
	EventBus.hour_changed.connect(_on_hour_changed)
	EventBus.day_started.connect(_on_day_started)
	EventBus.construction_completed.connect(_on_district_changed)
	EventBus.district_disabled.connect(_on_district_changed)
	EventBus.district_damaged.connect(_on_district_changed)
	EventBus.district_repaired.connect(_on_district_changed)
	EventBus.quest_resolved.connect(_on_quest_resolved)
	
	_emit_population_changed()


func _on_hour_changed(hour: float) -> void:
	_process_migration()
	_process_overflow(hour)
	_process_food_consumption()


func _on_day_started(_day: int) -> void:
	_process_passive_quest_losses()


func _on_district_changed(_arg1, _arg2 = null) -> void:
	var new_max = get_max_population()
	EventBus.max_population_changed.emit(new_max)
	_emit_population_changed()


func _on_quest_resolved(quest: Quest, success: bool) -> void:
	if not success and quest.data.population_loss_on_fail > 0:
		remove_citizens(quest.data.population_loss_on_fail, "quest failure")


func get_max_population() -> int:
	var max_pop = ConfigManager.config.base_max_population
	
	var grid = GameManager.hex_grid
	if not grid:
		return max_pop
	
	for tile in grid.get_built_tiles():
		if tile.state != GameEnums.TileState.BUILT:
			continue
		if tile.district_data:
			max_pop += tile.district_data.housing_capacity
	
	return max(0, max_pop)


func _process_migration() -> void:
	var appeal = AppealManager.get_appeal()
	var max_pop = get_max_population()
	
	if appeal > 0 and population < max_pop:
		var growth_chance = float(appeal) / 100.0
		if randf() < growth_chance:
			add_citizens(1)
	
	elif appeal < 0 and population > 0:
		var loss_chance = abs(float(appeal)) / 100.0
		if randf() < loss_chance:
			remove_citizens(1, "low appeal")


func _process_overflow(hour: float) -> void:
	var interval = ConfigManager.config.overflow_check_interval_hours
	
	if _last_overflow_check_hour < 0:
		_last_overflow_check_hour = hour
		return
	
	var hours_passed = hour - _last_overflow_check_hour
	if hours_passed < 0:
		hours_passed += 24.0
	
	if hours_passed >= interval:
		_last_overflow_check_hour = hour
		
		var max_pop = get_max_population()
		if population > max_pop:
			remove_citizens(1, "overcrowding")


func _process_food_consumption() -> void:
	if population <= 0:
		return
	
	var config = ConfigManager.config
	var food_per_hour = (population * config.food_per_citizen) / float(config.hours_per_day)
	
	_food_consumption_accumulator += food_per_hour
	
	if _food_consumption_accumulator >= 1.0:
		var food_needed = int(_food_consumption_accumulator)
		var food_available = ResourceManager.get_food()
		
		if food_available >= food_needed:
			ResourceManager.spend_type(GameEnums.ResourceType.FOOD, food_needed)
			_food_consumption_accumulator -= food_needed
		else:
			ResourceManager.spend_type(GameEnums.ResourceType.FOOD, food_available)
			_food_consumption_accumulator = 0.0
			remove_citizens(1, "starvation")


func _process_passive_quest_losses() -> void:
	for quest in QuestManager.active_quests:
		if quest.data.population_loss_passive > 0:
			remove_citizens(quest.data.population_loss_passive, "quest effect")


func add_citizens(amount: int) -> void:
	var max_pop = get_max_population()
	var actual_amount = min(amount, max_pop - population)
	
	if actual_amount <= 0:
		return
	
	population += actual_amount
	EventBus.citizens_arrived.emit(actual_amount)
	_emit_population_changed()


func remove_citizens(amount: int, reason: String) -> void:
	var actual_amount = min(amount, population)
	
	if actual_amount <= 0:
		return
	
	population -= actual_amount
	EventBus.citizens_left.emit(actual_amount, reason)
	_emit_population_changed()
	
	if population <= 0:
		_trigger_game_over()


func _emit_population_changed() -> void:
	EventBus.population_changed.emit(population, get_max_population())


func _trigger_game_over() -> void:
	print("=== GAME OVER ===")
	print("All citizens have left the city.")
	EventBus.game_over.emit()


func get_population() -> int:
	return population
