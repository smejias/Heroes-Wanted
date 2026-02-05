extends PanelContainer

signal confirmed
signal cancelled

@onready var district_name_label: Label = %DistrictNameLabel
@onready var cost_label: Label = %CostLabel
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton

var _district: DistrictData
var _tile: Tile


func _ready() -> void:
	add_to_group("build_confirmation_popup")
	confirm_button.pressed.connect(_on_confirm)
	cancel_button.pressed.connect(_on_cancel)
	visible = false


func show_confirmation(district: DistrictData, tile: Tile) -> void:
	_district = district
	_tile = tile
	
	district_name_label.text = district.display_name
	
	var costs: Array[String] = []
	if district.gold_cost > 0:
		costs.append("%d Gold" % district.gold_cost)
	if district.food_cost > 0:
		costs.append("%d Food" % district.food_cost)
	if district.materials_cost > 0:
		costs.append("%d Materials" % district.materials_cost)
	cost_label.text = "Cost: " + (", ".join(costs) if costs.size() > 0 else "Free")
	
	visible = true


func _on_confirm() -> void:
	visible = false
	confirmed.emit()


func _on_cancel() -> void:
	visible = false
	cancelled.emit()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel"):
		_on_cancel()
		get_viewport().set_input_as_handled()
