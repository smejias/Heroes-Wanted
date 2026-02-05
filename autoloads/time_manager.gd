extends Node

var seconds_per_day: float
var hours_per_day: int
var day_start_hour: int
var paused: bool = false

var current_day: int = 1
var current_hour: float
var _elapsed_seconds: float = 0.0

var time_scale: float = 1.0
var _available_speeds: Array[float] = [1.0, 2.0, 4.0]
var _current_speed_index: int = 0


func _ready() -> void:
	seconds_per_day = ConfigManager.config.seconds_per_day
	hours_per_day = ConfigManager.config.hours_per_day
	day_start_hour = ConfigManager.config.day_start_hour
	current_hour = float(day_start_hour)
	
	GameManager.register_time_manager(self)


func _process(delta: float) -> void:
	if paused:
		return
	
	_elapsed_seconds += delta
	_update_time(delta)


func _update_time(delta: float) -> void:
	var hours_per_second = float(hours_per_day) / seconds_per_day
	var previous_hour = int(current_hour)
	
	current_hour += hours_per_second * delta
	
	if int(current_hour) != previous_hour:
		EventBus.hour_changed.emit(current_hour)
	
	if current_hour >= hours_per_day:
		current_hour -= hours_per_day
		_advance_day()


func _advance_day() -> void:
	current_day += 1
	EventBus.day_started.emit(current_day)


func get_formatted_time() -> String:
	var h = int(current_hour)
	var m = int((current_hour - h) * 60)
	return "%02d:%02d" % [h, m]


func get_day() -> int:
	return current_day


func get_hour() -> float:
	return current_hour


func get_normalized_time() -> float:
	return current_hour / float(hours_per_day)


func is_daytime() -> bool:
	return current_hour >= 6.0 and current_hour < 20.0


func pause() -> void:
	paused = true


func resume() -> void:
	paused = false


func set_time_scale(scale: float) -> void:
	Engine.time_scale = scale

func cycle_speed() -> void:
	_current_speed_index = (_current_speed_index + 1) % _available_speeds.size()
	time_scale = _available_speeds[_current_speed_index]
	Engine.time_scale = time_scale
	EventBus.time_scale_changed.emit(time_scale)


func set_speed(scale: float) -> void:
	time_scale = scale
	Engine.time_scale = scale
	
	for i in range(_available_speeds.size()):
		if _available_speeds[i] == scale:
			_current_speed_index = i
			break
	
	EventBus.time_scale_changed.emit(time_scale)


func reset_speed() -> void:
	set_speed(1.0)
