class_name Party
extends RefCounted

var id: StringName
var display_name: String
var level: int = 1
var state: GameEnums.PartyState = GameEnums.PartyState.AVAILABLE
var quest_duration: int = 2
var work_days: int = 0

var arrival_day: int = 0
var stay_duration: int = 5
var tags: Array[StringName] = []


func get_hire_cost() -> int:
	var config = ConfigManager.config
	return config.party_base_cost + (level * config.party_cost_per_level)


func get_upfront_cost() -> int:
	return get_hire_cost() / 2


func get_completion_cost() -> int:
	return get_hire_cost() - get_upfront_cost()


func get_success_bonus() -> float:
	return level * 0.05


func get_days_remaining(current_day: int) -> int:
	return max(0, (arrival_day + stay_duration) - current_day)


func is_leaving_soon(current_day: int, warning_days: int) -> bool:
	return get_days_remaining(current_day) <= warning_days
