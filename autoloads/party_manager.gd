extends Node

var parties_in_city: Array[Party] = []
var working_parties: Array[Party] = []
var _party_pool: Array[Party] = []

var _party_counter: int = 0

var _emissary_active: bool = false
var _emissary_arrival_hour: float = 0.0
var _emissary_arrival_day: int = 0
var _cooldown_end_hour: float = 0.0
var _cooldown_end_day: int = 0


func _ready() -> void:
	EventBus.day_started.connect(_on_day_started)
	EventBus.hour_changed.connect(_on_hour_changed)
	EventBus.quest_selected_for_assignment.connect(_on_quest_selected)
	EventBus.quest_resolved.connect(_on_quest_resolved)
	
	_generate_party_pool()
	_spawn_initial_parties()


func _generate_party_pool() -> void:
	for i in range(20):
		var party = _create_party(randi_range(1, 5))
		_party_pool.append(party)


func _create_party(level: int) -> Party:
	_party_counter += 1
	
	var party = Party.new()
	party.id = StringName("party_%d" % _party_counter)
	party.display_name = _generate_party_name()
	party.level = level
	party.quest_duration = max(1, 4 - level + randi_range(0, 1))
	party.state = GameEnums.PartyState.AVAILABLE
	
	return party


func _generate_party_name() -> String:
	var adjectives = ["Brave", "Swift", "Iron", "Shadow", "Golden", "Silver", "Wild", "Storm", "Crimson", "Azure"]
	var nouns = ["Knights", "Rangers", "Wolves", "Hawks", "Guards", "Blades", "Shields", "Hunters", "Wanderers", "Seekers"]
	return adjectives.pick_random() + " " + nouns.pick_random()


func _spawn_initial_parties() -> void:
	for i in range(2):
		_try_spawn_party()


func _on_day_started(_day: int) -> void:
	_check_departures()
	_check_departure_warnings()
	_try_spawn_party()


func _on_hour_changed(_hour: float) -> void:
	_check_emissary_arrival()


func _check_departures() -> void:
	var current_day = TimeManager.get_day()
	
	for party in parties_in_city.duplicate():
		if party.get_days_remaining(current_day) <= 0:
			_party_departs(party)


func _check_departure_warnings() -> void:
	var current_day = TimeManager.get_day()
	var warning_days = ConfigManager.config.party_departure_warning_days
	
	for party in parties_in_city:
		if party.get_days_remaining(current_day) == warning_days:
			EventBus.party_leaving_soon.emit(party)


func _party_departs(party: Party) -> void:
	parties_in_city.erase(party)
	_party_pool.append(party)
	EventBus.party_departed.emit(party)


func _try_spawn_party() -> void:
	if parties_in_city.size() >= AppealManager.get_max_parties():
		return
	
	if randf() > ConfigManager.config.party_spawn_check_chance:
		return
	
	var max_level = AppealManager.get_max_party_level()
	var valid_parties = _party_pool.filter(func(p): return p.level <= max_level)
	
	if valid_parties.is_empty():
		var party = _create_party(randi_range(1, max_level))
		_spawn_party(party)
	else:
		var party = valid_parties.pick_random()
		_party_pool.erase(party)
		_spawn_party(party)


func _spawn_party(party: Party) -> void:
	party.arrival_day = TimeManager.get_day()
	party.stay_duration = AppealManager.get_stay_duration()
	party.state = GameEnums.PartyState.AVAILABLE
	
	parties_in_city.append(party)
	EventBus.party_arrived.emit(party)


func spawn_random_party() -> void:
	var max_level = AppealManager.get_max_party_level()
	var valid_parties = _party_pool.filter(func(p): return p.level <= max_level)
	
	var party: Party
	if valid_parties.is_empty():
		party = _create_party(randi_range(1, max_level))
	else:
		party = valid_parties.pick_random()
		_party_pool.erase(party)
	
	_spawn_party(party)


func hire_party(party: Party, quest: Quest) -> bool:
	if party.state != GameEnums.PartyState.AVAILABLE:
		return false
	
	var upfront_cost = party.get_upfront_cost()
	if ResourceManager.get_gold() < upfront_cost:
		return false
	
	ResourceManager.spend_type(GameEnums.ResourceType.GOLD, upfront_cost)
	
	party.state = GameEnums.PartyState.WORKING
	party.work_days = party.quest_duration
	
	parties_in_city.erase(party)
	working_parties.append(party)
	
	QuestManager.assign_party_to_quest(quest, party)
	EventBus.party_hired.emit(party)
	
	return true


func _on_quest_resolved(quest: Quest, success: bool) -> void:
	var party = quest.assigned_party
	if not party:
		return
	
	if success:
		var completion_cost = party.get_completion_cost()
		if ResourceManager.get_gold() >= completion_cost:
			ResourceManager.spend_type(GameEnums.ResourceType.GOLD, completion_cost)
	
	_release_party(party)


func _release_party(party: Party) -> void:
	party.state = GameEnums.PartyState.AVAILABLE
	party.arrival_day = TimeManager.get_day()
	party.stay_duration = AppealManager.get_stay_duration()
	
	working_parties.erase(party)
	parties_in_city.append(party)
	EventBus.party_available.emit(party)


func _on_quest_selected(quest: Quest) -> void:
	EventBus.show_party_selection.emit(quest)


# Emissary System

func send_emissary() -> bool:
	if not can_send_emissary():
		return false
	
	var config = ConfigManager.config
	
	if not ResourceManager.spend_type(GameEnums.ResourceType.GOLD, config.emissary_cost):
		return false
	
	_emissary_active = true
	
	var current_hour = TimeManager.get_hour()
	var current_day = TimeManager.get_day()
	var arrival_hours = current_hour + config.emissary_travel_hours
	
	_emissary_arrival_day = current_day + int(arrival_hours / 24.0)
	_emissary_arrival_hour = fmod(arrival_hours, 24.0)
	
	EventBus.emissary_sent.emit()
	
	return true


func _check_emissary_arrival() -> void:
	if not _emissary_active:
		return
	
	var current_day = TimeManager.get_day()
	var current_hour = TimeManager.get_hour()
	
	var arrived = false
	if current_day > _emissary_arrival_day:
		arrived = true
	elif current_day == _emissary_arrival_day and current_hour >= _emissary_arrival_hour:
		arrived = true
	
	if arrived:
		_emissary_active = false
		_start_cooldown()
		spawn_random_party()
		EventBus.emissary_arrived.emit()


func _start_cooldown() -> void:
	var config = ConfigManager.config
	var current_hour = TimeManager.get_hour()
	var current_day = TimeManager.get_day()
	var cooldown_hours = current_hour + config.emissary_cooldown_hours
	
	_cooldown_end_day = current_day + int(cooldown_hours / 24.0)
	_cooldown_end_hour = fmod(cooldown_hours, 24.0)


func can_send_emissary() -> bool:
	if _emissary_active:
		return false
	
	if is_on_cooldown():
		return false
	
	if parties_in_city.size() >= AppealManager.get_max_parties():
		return false
	
	if ResourceManager.get_gold() < ConfigManager.config.emissary_cost:
		return false
	
	return true


func is_on_cooldown() -> bool:
	var current_day = TimeManager.get_day()
	var current_hour = TimeManager.get_hour()
	
	if current_day < _cooldown_end_day:
		return true
	if current_day == _cooldown_end_day and current_hour < _cooldown_end_hour:
		return true
	
	return false


func is_emissary_active() -> bool:
	return _emissary_active


func get_emissary_status() -> String:
	if _emissary_active:
		var hours_left = _get_hours_until(_emissary_arrival_day, _emissary_arrival_hour)
		return "Arriving in %.1f hours" % hours_left
	
	if is_on_cooldown():
		var hours_left = _get_hours_until(_cooldown_end_day, _cooldown_end_hour)
		return "Cooldown: %.1f hours" % hours_left
	
	return ""


func _get_hours_until(target_day: int, target_hour: float) -> float:
	var current_day = TimeManager.get_day()
	var current_hour = TimeManager.get_hour()
	
	var days_diff = target_day - current_day
	var hours_diff = target_hour - current_hour
	
	return (days_diff * 24.0) + hours_diff


# Getters

func get_available_parties() -> Array[Party]:
	return parties_in_city.filter(func(p): return p.state == GameEnums.PartyState.AVAILABLE)


func get_working_parties() -> Array[Party]:
	return working_parties
