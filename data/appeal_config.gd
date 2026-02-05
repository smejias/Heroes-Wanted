class_name AppealConfig
extends Resource

@export_group("Base")
@export var base_appeal: int = 10

@export_group("Resources")
@export var no_food_penalty: int = -15
@export var starvation_penalty_per_hour: int = -5

@export_group("Population")
@export var overcrowding_penalty: int = -10

@export_group("Districts")
@export var disabled_district_penalty: int = -3
@export var damaged_district_penalty: int = -5

@export_group("Quests")
@export var active_dangerous_quest_penalty: int = -2
@export var recently_expired_quest_penalty: int = -5
@export var recently_expired_duration_days: int = 3
