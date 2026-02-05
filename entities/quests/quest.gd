class_name Quest
extends RefCounted

var data: QuestData
var state: GameEnums.QuestState = GameEnums.QuestState.ACTIVE
var source_tile: Tile
var days_remaining: int
var assigned_party: Party = null


func _init(quest_data: QuestData, tile: Tile) -> void:
	data = quest_data
	source_tile = tile
	days_remaining = quest_data.deadline_days


func tick_day() -> void:
	if state != GameEnums.QuestState.ACTIVE:
		return
	
	days_remaining -= 1
	
	if days_remaining <= 0:
		expire()


func assign_party(party: Party) -> void:
	if state != GameEnums.QuestState.ACTIVE:
		return
	
	assigned_party = party
	state = GameEnums.QuestState.ASSIGNED


func resolve(success: bool) -> void:
	state = GameEnums.QuestState.RESOLVED
	
	if success:
		if data.gold_reward > 0:
			ResourceManager.add(ResourceManager.Type.GOLD, data.gold_reward)
		if data.food_reward > 0:
			ResourceManager.add(ResourceManager.Type.FOOD, data.food_reward)
		if data.materials_reward > 0:
			ResourceManager.add(ResourceManager.Type.MATERIALS, data.materials_reward)
		
		if source_tile and source_tile.state == GameEnums.TileState.DISABLED:
			source_tile.repair()
	
	assigned_party = null


func expire() -> void:
	state = GameEnums.QuestState.EXPIRED
	
	if source_tile:
		if source_tile.state == GameEnums.TileState.BUILT:
			source_tile.disable()
		elif source_tile.state == GameEnums.TileState.DISABLED:
			source_tile.damage()
	
	EventBus.quest_expired.emit(self)
