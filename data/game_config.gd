class_name GameConfig
extends Resource

@export_group("Time")
@export var seconds_per_day: float = 90.0
@export var hours_per_day: int = 24
@export var day_start_hour: int = 6

@export_group("Starting Resources")
@export var starting_gold: int = 500
@export var starting_food: int = 100
@export var starting_materials: int = 100

@export_group("Population")
@export var starting_population: int = 5
@export var base_max_population: int = 10
@export var growth_threshold: int = 20
@export var loss_threshold: int = 20
@export var overflow_check_interval_hours: float = 1.0
@export var food_per_citizen: float = 0.5

@export_group("Quests")
@export var max_active_quests: int = 3
@export var force_tutorial: bool = true
@export var tutorial_quest: QuestData

@export_group("Parties")
@export var base_max_parties: int = 3
@export var base_stay_duration: int = 5
@export var party_spawn_check_chance: float = 0.4
@export var party_departure_warning_days: int = 1

@export_group("Emissary")
@export var emissary_cost: int = 150
@export var emissary_travel_hours: float = 12.0
@export var emissary_cooldown_hours: float = 24.0

@export_group("Appeal System")
@export var appeal_config: AppealConfig
@export var appeal_level_thresholds: Array[int] = [0, 20, 40, 60, 80]

@export_group("Party Costs")
@export var party_base_cost: int = 30
@export var party_cost_per_level: int = 20

@export_group("Camera")
@export var camera_move_speed: float = 20.0
@export var camera_fast_multiplier: float = 2.0
@export var camera_zoom_speed: float = 2.0
@export var camera_min_distance: float = 10.0
@export var camera_max_distance: float = 60.0
@export var camera_orbit_speed: float = 90.0
