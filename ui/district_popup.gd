extends Control

# Quest Container
@onready var quest_container: PanelContainer = %QuestContainer
@onready var quest_label: Label = %QuestLabel
@onready var quest_difficulty_label: Label = %QuestDifficultyLabel
@onready var quest_requirement_label: Label = %QuestRequirementLabel
@onready var quest_description_label: Label = %QuestDescriptionLabel
@onready var assign_button: Button = %AssignButton

# Main Container
@onready var name_label: Label = %NameLabel
@onready var state_label: Label = %StateLabel
@onready var description_label: RichTextLabel = %RichTextLabel
@onready var input_label: RichTextLabel = %InputLabel
@onready var output_label: RichTextLabel = %OutputLabel
@onready var repair_button: Button = %RepairButton
@onready var close_button: Button = %CloseButton

var _current_tile: Tile = null
var _current_quest: Quest = null

const RESOURCE_ICONS = {
	"gold": "[img]res://assets/Icons/Pixel Art RPG/Misc/Golden Coin.png[/img]",
	"food": "[img]res://assets/Icons/Pixel Art RPG/Food/Bread.png[/img]",
	"materials": "[img]res://assets/Icons/Pixel Art RPG/Misc/Crate.png[/img]"
}


func _ready() -> void:
	
	add_to_group("district_popup")

	
	close_button.pressed.connect(_on_close_pressed)
	repair_button.pressed.connect(_on_repair_pressed)
	assign_button.pressed.connect(_on_assign_pressed)
	
	EventBus.district_disabled.connect(_on_district_state_changed)
	EventBus.district_damaged.connect(_on_district_state_changed)
	EventBus.district_repaired.connect(_on_district_state_changed)
	EventBus.quest_assigned.connect(_on_quest_changed)
	EventBus.quest_resolved.connect(_on_quest_changed)
	
	visible = false


func show_district(tile: Tile) -> void:
	_current_tile = tile
	_current_quest = _find_quest_for_tile(tile)
	
	_update_district_info()
	_update_quest_info()
	_center_camera_on_tile()
	
	visible = true


func _update_district_info() -> void:
	var data = _current_tile.district_data
	if not data:
		return
	
	name_label.text = data.display_name
	state_label.text = _get_state_text()
	description_label.text = data.description
	
	input_label.clear()
	input_label.append_text(_format_consumption(data))

	output_label.clear()
	output_label.append_text(_format_production(data))
	
	repair_button.disabled = _current_tile.state != GameEnums.TileState.DAMAGED
	
	_update_state_color()


func _get_state_text() -> String:
	match _current_tile.state:
		GameEnums.TileState.BUILT:
			if ProductionManager.is_district_paused(_current_tile):
				return "Paused"
			return "Working"
		GameEnums.TileState.DISABLED:
			return "Disabled"
		GameEnums.TileState.DAMAGED:
			return "Damaged"
		_:
			return "Unknown"


func _update_state_color() -> void:
	var color: Color
	match _current_tile.state:
		GameEnums.TileState.BUILT:
			if ProductionManager.is_district_paused(_current_tile):
				color = Color.ORANGE
			else:
				color = Color.GREEN
		GameEnums.TileState.DISABLED:
			color = Color.ORANGE
		GameEnums.TileState.DAMAGED:
			color = Color.RED
		_:
			color = Color.WHITE
	
	state_label.add_theme_color_override("font_color", color)


func _format_production(data: DistrictData) -> String:
	var parts: Array[String] = []
	
	if data.gold_production > 0:
		parts.append("%d %s" % [data.gold_production, RESOURCE_ICONS["gold"]])
	if data.food_production > 0:
		parts.append("%d %s" % [data.food_production, RESOURCE_ICONS["food"]])
	if data.materials_production > 0:
		parts.append("%d %s" % [data.materials_production, RESOURCE_ICONS["materials"]])
	
	return "\n".join(parts) if parts.size() > 0 else "None"


func _format_consumption(data: DistrictData) -> String:
	var parts: Array[String] = []
	
	if data.gold_consumption > 0:
		parts.append("%d %s" % [data.gold_consumption, RESOURCE_ICONS["gold"]])
	if data.food_consumption > 0:
		parts.append("%d %s" % [data.food_consumption, RESOURCE_ICONS["food"]])
	if data.materials_consumption > 0:
		parts.append("%d %s" % [data.materials_consumption, RESOURCE_ICONS["materials"]])
	
	return "\n".join(parts) if parts.size() > 0 else "None"


func _update_quest_info() -> void:
	if not _current_quest:
		quest_container.visible = false
		return
	
	quest_container.visible = true
	
	var data = _current_quest.data
	quest_label.text = data.display_name
	quest_difficulty_label.text = GameEnums.QuestDifficulty.keys()[data.difficulty]
	quest_requirement_label.text = "Party Lvl %d+" % data.min_party_level
	quest_description_label.text = data.description
	
	assign_button.disabled = _current_quest.state != GameEnums.QuestState.ACTIVE


func _find_quest_for_tile(tile: Tile) -> Quest:
	for quest in QuestManager.active_quests:
		if quest.source_tile == tile:
			return quest
	return null


func _center_camera_on_tile() -> void:
	var camera_rig = get_tree().get_first_node_in_group("camera_rig")
	if camera_rig and camera_rig.has_method("center_on_position"):
		camera_rig.center_on_position(_current_tile.global_position)


func _on_close_pressed() -> void:
	_current_tile = null
	_current_quest = null
	visible = false


func _on_repair_pressed() -> void:
	if not _current_tile:
		return
	
	if _current_tile.state != GameEnums.TileState.DAMAGED:
		return
	
	# TODO: Definir costo de reparación
	_current_tile.repair()
	_update_district_info()


func _on_assign_pressed() -> void:
	if _current_quest:
		EventBus.quest_selected_for_assignment.emit(_current_quest)


func _on_district_state_changed(tile) -> void:
	if tile == _current_tile and visible:
		_update_district_info()


func _on_quest_changed(_arg1, _arg2 = null) -> void:
	if visible and _current_tile:
		_current_quest = _find_quest_for_tile(_current_tile)
		_update_quest_info()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
