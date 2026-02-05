extends DirectionalLight3D

@export_group("Sun Path")
@export var sun_start_angle: float = 0.0
@export var sun_end_angle: float = 180.0
@export var sun_max_height: float = 60.0
@export var sunrise_hour: float = 6.0
@export var sunset_hour: float = 20.0

@export_group("Colors")
@export var night_color: Color = Color(0.2, 0.25, 0.4)
@export var dawn_color: Color = Color(1.0, 0.6, 0.4)
@export var day_color: Color = Color(1.0, 0.95, 0.9)
@export var dusk_color: Color = Color(1.0, 0.4, 0.3)

@export_group("Intensity")
@export var night_intensity: float = 0.05
@export var day_intensity: float = 1.2


func _process(delta: float) -> void:
	var hour = TimeManager.get_hour()
	_update_sun_position(hour)
	_update_sun_color(hour)


func _update_sun_position(hour: float) -> void:
	var day_progress = _get_day_progress(hour)
	
	var yaw = lerp(sun_start_angle, sun_end_angle, day_progress)
	var pitch = sin(day_progress * PI) * sun_max_height
	
	if day_progress <= 0.0 or day_progress >= 1.0:
		pitch = -10.0
	
	rotation_degrees = Vector3(-pitch, yaw, 0)


func _update_sun_color(hour: float) -> void:
	var color: Color
	var intensity: float
	
	if hour < sunrise_hour - 1.0:
		color = night_color
		intensity = night_intensity
	elif hour < sunrise_hour + 1.0:
		var t = (hour - (sunrise_hour - 1.0)) / 2.0
		color = night_color.lerp(dawn_color, t)
		intensity = lerp(night_intensity, day_intensity * 0.7, t)
	elif hour < sunrise_hour + 2.5:
		var t = (hour - (sunrise_hour + 1.0)) / 1.5
		color = dawn_color.lerp(day_color, t)
		intensity = lerp(day_intensity * 0.7, day_intensity, t)
	elif hour < sunset_hour - 2.5:
		color = day_color
		intensity = day_intensity
	elif hour < sunset_hour - 1.0:
		var t = (hour - (sunset_hour - 2.5)) / 1.5
		color = day_color.lerp(dusk_color, t)
		intensity = lerp(day_intensity, day_intensity * 0.7, t)
	elif hour < sunset_hour + 1.0:
		var t = (hour - (sunset_hour - 1.0)) / 2.0
		color = dusk_color.lerp(night_color, t)
		intensity = lerp(day_intensity * 0.7, night_intensity, t)
	else:
		color = night_color
		intensity = night_intensity
	
	light_color = color
	light_energy = intensity


func _get_day_progress(hour: float) -> float:
	if hour < sunrise_hour:
		return 0.0
	if hour > sunset_hour:
		return 1.0
	return (hour - sunrise_hour) / (sunset_hour - sunrise_hour)
