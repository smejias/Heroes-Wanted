extends PanelContainer

@onready var party_list: VBoxContainer = %PartyList
@onready var no_parties_label: Label = %NoPartiesLabel
@onready var title_label: Label = %TitleLabel
@onready var emissary_button: Button = %EmissaryButton
@onready var emissary_status_label: Label = %EmissaryStatusLabel

var _selected_quest: Quest = null


func _ready() -> void:
	EventBus.show_party_selection.connect(_on_show_party_selection)
	EventBus.party_arrived.connect(_on_parties_changed)
	EventBus.party_hired.connect(_on_parties_changed)
	EventBus.party_available.connect(_on_parties_changed)
	EventBus.party_departed.connect(_on_parties_changed)
	EventBus.emissary_sent.connect(_on_emissary_changed)
	EventBus.emissary_arrived.connect(_on_emissary_changed)
	EventBus.hour_changed.connect(_on_hour_changed)
	
	emissary_button.pressed.connect(_on_emissary_pressed)
	
	visible = false


func _on_show_party_selection(quest: Quest) -> void:
	_selected_quest = quest
	title_label.text = "Assign Party to: " + quest.data.display_name
	visible = true
	_refresh()


func _on_parties_changed(_party = null) -> void:
	if visible:
		_refresh()


func _on_emissary_changed() -> void:
	if visible:
		_refresh_emissary_status()


func _on_hour_changed(_hour: float) -> void:
	if visible:
		_refresh_emissary_status()


func _refresh() -> void:
	for child in party_list.get_children():
		child.queue_free()
	
	var parties = PartyManager.get_available_parties()
	no_parties_label.visible = parties.is_empty()
	
	for party in parties:
		var item = _create_party_item(party)
		party_list.add_child(item)
	
	_refresh_emissary_status()


func _refresh_emissary_status() -> void:
	var can_send = PartyManager.can_send_emissary()
	var cost = ConfigManager.config.emissary_cost
	
	emissary_button.text = "Send Emissary (%d G)" % cost
	emissary_button.disabled = not can_send
	
	var status = PartyManager.get_emissary_status()
	emissary_status_label.text = status
	emissary_status_label.visible = status != ""


func _create_party_item(party: Party) -> Control:
	var container = HBoxContainer.new()
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(info)
	
	var name_label = Label.new()
	name_label.text = "%s (Lvl %d)" % [party.display_name, party.level]
	info.add_child(name_label)
	
	var stats_label = Label.new()
	var days_left = party.get_days_remaining(TimeManager.get_day())
	stats_label.text = "Duration: %d days | Cost: %d G (½ now) | Leaves in: %d days" % [
		party.quest_duration, 
		party.get_hire_cost(),
		days_left
	]
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	if party.is_leaving_soon(TimeManager.get_day(), ConfigManager.config.party_departure_warning_days):
		stats_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	
	info.add_child(stats_label)
	
	var hire_btn = Button.new()
	hire_btn.text = "Hire (%d G)" % party.get_upfront_cost()
	hire_btn.disabled = ResourceManager.get_gold() < party.get_upfront_cost()
	hire_btn.pressed.connect(_on_hire_pressed.bind(party))
	container.add_child(hire_btn)
	
	return container


func _on_hire_pressed(party: Party) -> void:
	if not _selected_quest:
		return
	
	if PartyManager.hire_party(party, _selected_quest):
		_selected_quest = null
		visible = false


func _on_emissary_pressed() -> void:
	if PartyManager.send_emissary():
		_refresh_emissary_status()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		_selected_quest = null
		visible = false
		get_viewport().set_input_as_handled()
