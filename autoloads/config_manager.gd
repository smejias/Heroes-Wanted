extends Node

const CONFIG_PATH = "res://data/game config/game_config.tres"

var config: GameConfig


func _ready() -> void:
	config = load(CONFIG_PATH) as GameConfig
	if not config:
		push_error("Failed to load GameConfig from: " + CONFIG_PATH)
