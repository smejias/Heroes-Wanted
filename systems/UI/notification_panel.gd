extends VBoxContainer

const NOTIFICATION_DURATION: float = 4.0
const MAX_NOTIFICATIONS: int = 5


func _ready() -> void:
	EventBus.notification_requested.connect(_on_notification_requested)


func _on_notification_requested(message: String, type: int) -> void:
	_add_notification(message, type)


func _add_notification(message: String, type: int) -> void:
	if get_child_count() >= MAX_NOTIFICATIONS:
		var oldest = get_child(0)
		oldest.queue_free()
	
	var panel = PanelContainer.new()
	var label = Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var color: Color
	match type:
		NotificationManager.Type.INFO:
			color = Color(0.8, 0.8, 0.8)
		NotificationManager.Type.WARNING:
			color = Color(1.0, 0.8, 0.2)
		NotificationManager.Type.SUCCESS:
			color = Color(0.2, 0.8, 0.2)
		NotificationManager.Type.DANGER:
			color = Color(0.9, 0.2, 0.2)
	
	label.add_theme_color_override("font_color", color)
	
	panel.add_child(label)
	add_child(panel)
	
	var tween = create_tween()
	tween.tween_interval(NOTIFICATION_DURATION)
	tween.tween_callback(panel.queue_free)
