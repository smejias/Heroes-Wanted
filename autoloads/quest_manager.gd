extends Node

var active_quests: Array[Quest] = []
var completed_quest_ids: Array[StringName] = []
var failed_quest_ids: Array[StringName] = []
var _tutorial_done: bool = false
var _all_known_quests: Dictionary = {}  # id -> QuestData


func _ready() -> void:
	EventBus.day_started.connect(_on_day_started)
	EventBus.construction_completed.connect(_on_construction_completed)
	
	call_deferred("_collect_all_quests")


func _collect_all_quests() -> void:
	var grid = GameManager.hex_grid
	if not grid:
		return
	
	for tile in grid.get_all_tiles():
		if tile.district_data:
			for quest_data in tile.district_data.possible_quests:
				if quest_data and quest_data.id:
					_all_known_quests[quest_data.id] = quest_data


func _register_quest_from_district(district_data: DistrictData) -> void:
	for quest_data in district_data.possible_quests:
		if quest_data and quest_data.id:
			_all_known_quests[quest_data.id] = quest_data


func _on_day_started(day: int) -> void:
	_tick_quests()
	_check_assigned_quests()
	_try_spawn_unlocked_quests()


func _tick_quests() -> void:
	for quest in active_quests.duplicate():
		if quest.state == GameEnums.QuestState.ACTIVE:
			quest.tick_day()
			
			if quest.state == GameEnums.QuestState.EXPIRED:
				_on_quest_expired(quest)


func _on_quest_expired(quest: Quest) -> void:
	failed_quest_ids.append(quest.data.id)
	active_quests.erase(quest)
	EventBus.quest_expired.emit(quest)


func _check_assigned_quests() -> void:
	for quest in active_quests.duplicate():
		if quest.state == GameEnums.QuestState.ASSIGNED and quest.assigned_party:
			quest.assigned_party.work_days -= 1
			
			if quest.assigned_party.work_days <= 0:
				_resolve_quest(quest)


func _resolve_quest(quest: Quest) -> void:
	var success_chance = quest.data.base_success_chance
	var party = quest.assigned_party
	
	if party:
		success_chance += party.get_success_bonus()
	
	var success = randf() < success_chance
	
	if success:
		completed_quest_ids.append(quest.data.id)
	else:
		failed_quest_ids.append(quest.data.id)
	
	quest.resolve(success)
	active_quests.erase(quest)
	EventBus.quest_resolved.emit(quest, success)


func _on_construction_completed(tile: Tile, district_data: DistrictData) -> void:
	_register_quest_from_district(district_data)
	
	var config = ConfigManager.config
	
	if config.force_tutorial and not _tutorial_done:
		if config.tutorial_quest:
			spawn_quest(config.tutorial_quest, tile)
		_tutorial_done = true
		return
	
	_try_spawn_quest(tile, district_data)


func _try_spawn_quest(tile: Tile, district_data: DistrictData) -> void:
	if active_quests.size() >= ConfigManager.config.max_active_quests:
		return
	
	if district_data.possible_quests.is_empty():
		return
	
	if randf() > district_data.quest_spawn_chance:
		return
	
	var valid_quests = _get_valid_quests(district_data.possible_quests)
	if valid_quests.is_empty():
		return
	
	var quest_data = valid_quests.pick_random() as QuestData
	if quest_data:
		spawn_quest(quest_data, tile)


func _try_spawn_unlocked_quests() -> void:
	if active_quests.size() >= ConfigManager.config.max_active_quests:
		return
	
	var grid = GameManager.hex_grid
	if not grid:
		return
	
	var built_tiles = grid.get_built_tiles()
	if built_tiles.is_empty():
		return
	
	for quest_id in _all_known_quests.keys():
		if active_quests.size() >= ConfigManager.config.max_active_quests:
			break
		
		var quest_data = _all_known_quests[quest_id] as QuestData
		if not quest_data:
			continue
		
		if _is_quest_active(quest_data.id):
			continue
		
		if not _has_requirements(quest_data):
			continue
		
		if not _are_requirements_met(quest_data):
			continue
		
		var valid_tile = _find_valid_tile_for_quest(quest_data, built_tiles)
		if valid_tile:
			spawn_quest(quest_data, valid_tile)


func _has_requirements(quest_data: QuestData) -> bool:
	return not quest_data.required_quests_success.is_empty() or not quest_data.required_quests_fail.is_empty()


func _find_valid_tile_for_quest(quest_data: QuestData, built_tiles: Array[Tile]) -> Tile:
	var valid_tiles: Array[Tile] = []
	
	for tile in built_tiles:
		if tile.state != GameEnums.TileState.BUILT:
			continue
		if not tile.district_data:
			continue
		if quest_data in tile.district_data.possible_quests:
			valid_tiles.append(tile)
	
	if valid_tiles.is_empty():
		return null
	
	return valid_tiles.pick_random()


func _get_valid_quests(possible_quests: Array[QuestData]) -> Array[QuestData]:
	var valid: Array[QuestData] = []
	
	for quest_data in possible_quests:
		if not quest_data:
			continue
		if _is_quest_active(quest_data.id):
			continue
		if not _are_requirements_met(quest_data):
			continue
		valid.append(quest_data)
	
	return valid


func _are_requirements_met(quest_data: QuestData) -> bool:
	var success_reqs = quest_data.required_quests_success
	var fail_reqs = quest_data.required_quests_fail
	
	if success_reqs.is_empty() and fail_reqs.is_empty():
		return true
	
	if quest_data.require_all:
		return _check_requirements_and(success_reqs, fail_reqs)
	else:
		return _check_requirements_or(success_reqs, fail_reqs)


func _check_requirements_and(success_reqs: Array[QuestData], fail_reqs: Array[QuestData]) -> bool:
	for req in success_reqs:
		if req and req.id not in completed_quest_ids:
			return false
	
	for req in fail_reqs:
		if req and req.id not in failed_quest_ids:
			return false
	
	return true


func _check_requirements_or(success_reqs: Array[QuestData], fail_reqs: Array[QuestData]) -> bool:
	for req in success_reqs:
		if req and req.id in completed_quest_ids:
			return true
	
	for req in fail_reqs:
		if req and req.id in failed_quest_ids:
			return true
	
	return success_reqs.is_empty() and fail_reqs.is_empty()


func _is_quest_active(quest_id: StringName) -> bool:
	for quest in active_quests:
		if quest.data.id == quest_id:
			return true
	return false


func spawn_quest(quest_data: QuestData, tile: Tile) -> void:
	if _is_quest_active(quest_data.id):
		return
	
	var quest = Quest.new(quest_data, tile)
	active_quests.append(quest)
	EventBus.quest_spawned.emit(quest)
	print("Quest spawned: ", quest_data.display_name)


func assign_party_to_quest(quest: Quest, party: Party) -> void:
	if quest.state != GameEnums.QuestState.ACTIVE:
		return
	
	quest.assign_party(party)
	EventBus.quest_assigned.emit(quest, party)


func get_active_quests() -> Array[Quest]:
	return active_quests.filter(func(q): return q.state == GameEnums.QuestState.ACTIVE)


func get_assigned_quests() -> Array[Quest]:
	return active_quests.filter(func(q): return q.state == GameEnums.QuestState.ASSIGNED)


func is_quest_completed(quest_id: StringName) -> bool:
	return quest_id in completed_quest_ids


func is_quest_failed(quest_id: StringName) -> bool:
	return quest_id in failed_quest_ids


func reset_quest_history() -> void:
	completed_quest_ids.clear()
	failed_quest_ids.clear()
