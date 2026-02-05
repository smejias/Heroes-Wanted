extends FoldableContainer

@onready var breakdown_list: VBoxContainer = $BreakdownList


func _ready() -> void:
	EventBus.appeal_changed.connect(_on_appeal_changed)
	_refresh()


func _on_appeal_changed(_total: int, _breakdown: Dictionary) -> void:
	_update_title()
	if not folded:
		_refresh()


func _update_title() -> void:
	var total = AppealManager.get_appeal()
	if total >= 0:
		title = "Appeal: +%d" % total
	else:
		title = "Appeal: %d" % total


func _refresh() -> void:
	_update_title()
	
	for child in breakdown_list.get_children():
		child.queue_free()
	
	var breakdown = AppealManager.get_breakdown()
	
	for factor_name in breakdown.keys():
		var value = breakdown[factor_name]
		var row = _create_row(factor_name, value)
		breakdown_list.add_child(row)


func _create_row(label_text: String, value: int) -> Control:
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	var value_label = Label.new()
	if value >= 0:
		value_label.text = "+%d" % value
		value_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		value_label.text = "%d" % value
		value_label.add_theme_color_override("font_color", Color.RED)
	
	hbox.add_child(value_label)
	
	return hbox
