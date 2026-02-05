extends PanelContainer

signal district_selected(district_data: DistrictData)

@export var districts_folder: String = "res://data/districts/"

@onready var district_list: HBoxContainer = %DistrictList

var districts: Array[DistrictData] = []
var _selected_district: DistrictData = null


func _ready() -> void:
	_load_districts()
	_populate_districts()
	
	EventBus.resources_changed.connect(_on_resources_changed)


func _on_resources_changed(_type: int, _amount: int) -> void:
	_refresh_buttons()


func _load_districts() -> void:
	var dir = DirAccess.open(districts_folder)
	if not dir:
		push_error("Cannot open districts folder: " + districts_folder)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path = districts_folder + file_name
			var resource = load(path)
			if resource is DistrictData:
				districts.append(resource)
		file_name = dir.get_next()
	
	dir.list_dir_end()


func _populate_districts() -> void:
	for child in district_list.get_children():
		child.queue_free()
	
	for district in districts:
		if not district:
			continue
		var button = Button.new()
		button.name = district.id
		button.text = _format_district_text(district)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_district_pressed.bind(district))
		district_list.add_child(button)
	
	_refresh_buttons()


func _refresh_buttons() -> void:
	for child in district_list.get_children():
		if child is Button:
			var district = _get_district_by_id(StringName(child.name))
			if district:
				var can_afford = ResourceManager.can_afford(district)
				child.disabled = not can_afford
				if can_afford:
					child.modulate = Color.WHITE
				else:
					child.modulate = Color(0.5, 0.5, 0.5, 1.0)


func _get_district_by_id(id: StringName) -> DistrictData:
	for district in districts:
		if district.id == id:
			return district
	return null


func _format_district_text(district: DistrictData) -> String:
	var cost_parts: Array[String] = []
	if district.gold_cost > 0:
		cost_parts.append("%d G" % district.gold_cost)
	if district.food_cost > 0:
		cost_parts.append("%d F" % district.food_cost)
	if district.materials_cost > 0:
		cost_parts.append("%d M" % district.materials_cost)
	
	var cost_str = ", ".join(cost_parts) if cost_parts.size() > 0 else "Free"
	return "%s (%s)" % [district.display_name, cost_str]


func _on_district_pressed(district: DistrictData) -> void:
	if not ResourceManager.can_afford(district):
		return
	
	_selected_district = district
	district_selected.emit(district)
	EventBus.district_selected.emit(district)


func clear_selection() -> void:
	_selected_district = null
