class_name QuestData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String

@export_group("Difficulty")
@export var difficulty: GameEnums.QuestDifficulty = GameEnums.QuestDifficulty.EASY
@export var deadline_days: int = 5
@export var base_success_chance: float = 0.7

@export_group("Rewards")
@export var gold_reward: int = 100
@export var food_reward: int = 0
@export var materials_reward: int = 0

@export_group("Party Requirements")
@export var min_party_level: int = 1
@export var recommended_party_size: int = 3

@export_group("Population Effects")
@export var population_loss_on_fail: int = 0
@export var population_loss_passive: int = 0

@export_group("Quest Requirements")
@export var require_all: bool = true
@export var required_quests_success: Array[QuestData]
@export var required_quests_fail: Array[QuestData]
