extends PanelContainer

@onready var quest_list: VBoxContainer = %QuestList
@onready var no_quests_label: Label = %NoQuestsLabel


func _ready() -> void:
	EventBus.quest_spawned.connect(_on_refresh)
	EventBus.quest_resolved.connect(_on_quest_resolved)
	EventBus.quest_expired.connect(_on_refresh)
	EventBus.quest_assigned.connect(_on_quest_assigned)
	EventBus.day_started.connect(_on_day_started)
	_refresh()


func _on_refresh(_arg = null) -> void:
	_refresh()


func _on_quest_assigned(_quest, _party) -> void:
	_refresh()


func _on_quest_resolved(_quest, _success) -> void:
	_refresh()

func _on_day_started(_day: int) -> void:
	_refresh()


func _refresh() -> void:
	for child in quest_list.get_children():
		child.queue_free()
	
	var quests = QuestManager.active_quests
	no_quests_label.visible = quests.is_empty()
	
	for quest in quests:
		var item = _create_quest_item(quest)
		quest_list.add_child(item)


func _create_quest_item(quest: Quest) -> Control:
	var container = VBoxContainer.new()
	
	var header = HBoxContainer.new()
	container.add_child(header)
	
	var name_label = Label.new()
	name_label.text = quest.data.display_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	
	var days_label = Label.new()
	days_label.text = "%d days" % quest.days_remaining
	if quest.days_remaining <= 2:
		days_label.add_theme_color_override("font_color", Color.RED)
	elif quest.days_remaining <= 4:
		days_label.add_theme_color_override("font_color", Color.YELLOW)
	header.add_child(days_label)
	
	var state_label = Label.new()
	match quest.state:
		GameEnums.QuestState.ACTIVE:
			state_label.text = "⚠ Active"
			state_label.add_theme_color_override("font_color", Color.ORANGE)
		GameEnums.QuestState.ASSIGNED:
			state_label.text = "⚔ In Progress"
			state_label.add_theme_color_override("font_color", Color.CYAN)
	container.add_child(state_label)
	
	var reward_label = Label.new()
	var rewards: Array[String] = []
	if quest.data.gold_reward > 0:
		rewards.append("%d G" % quest.data.gold_reward)
	if quest.data.food_reward > 0:
		rewards.append("%d F" % quest.data.food_reward)
	if quest.data.materials_reward > 0:
		rewards.append("%d M" % quest.data.materials_reward)
	reward_label.text = "Reward: " + ", ".join(rewards)
	reward_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	container.add_child(reward_label)
	
	if quest.state == GameEnums.QuestState.ACTIVE:
		var assign_btn = Button.new()
		assign_btn.text = "Assign Party"
		assign_btn.pressed.connect(_on_assign_pressed.bind(quest))
		container.add_child(assign_btn)
	
	var separator = HSeparator.new()
	container.add_child(separator)
	
	return container


func _on_assign_pressed(quest: Quest) -> void:
	EventBus.quest_selected_for_assignment.emit(quest)
