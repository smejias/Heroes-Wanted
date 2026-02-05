extends PanelContainer

@onready var party_list: VBoxContainer = %PartyInTownList
@onready var appeal_label: Label = %AppealLabel


func _ready() -> void:
	EventBus.party_arrived.connect(_on_update)
	EventBus.party_departed.connect(_on_update)
	EventBus.party_hired.connect(_on_update)
	EventBus.party_available.connect(_on_update)
	EventBus.day_started.connect(_on_day_update)
	EventBus.construction_completed.connect(_on_update)
	
	_refresh()


func _on_update(_arg = null, _arg2 = null) -> void:
	_refresh()


func _on_day_update(_day: int) -> void:
	_refresh()


func _refresh() -> void:
	appeal_label.text = "Appeal: %d (Max Lvl %d)" % [AppealManager.get_appeal(), AppealManager.get_max_party_level()]
	
	for child in party_list.get_children():
		child.queue_free()
	
	var parties = PartyManager.get_available_parties()
	
	if parties.is_empty():
		var label = Label.new()
		label.text = "No parties in city"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		party_list.add_child(label)
		return
	
	for party in parties:
		var item = _create_party_row(party)
		party_list.add_child(item)


func _create_party_row(party: Party) -> Control:
	var hbox = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = "%s (Lvl %d)" % [party.display_name, party.level]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	var days_left = party.get_days_remaining(TimeManager.get_day())
	var days_label = Label.new()
	days_label.text = "%d days" % days_left
	
	if party.is_leaving_soon(TimeManager.get_day(), ConfigManager.config.party_departure_warning_days):
		days_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	else:
		days_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	hbox.add_child(days_label)
	
	return hbox
