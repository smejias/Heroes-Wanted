extends Node3D

var move_speed: float
var fast_multiplier: float
var zoom_speed: float
var min_distance: float
var max_distance: float
var orbit_speed: float

var _target_position: Vector3 = Vector3.ZERO
var _distance: float = 30.0
var _yaw: float = 0.0
var _pitch: float = 45.0
var _is_rotating: bool = false

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	add_to_group("camera_rig")
	var config = ConfigManager.config
	move_speed = config.camera_move_speed
	fast_multiplier = config.camera_fast_multiplier
	zoom_speed = config.camera_zoom_speed
	min_distance = config.camera_min_distance
	max_distance = config.camera_max_distance
	orbit_speed = config.camera_orbit_speed
	
	_update_camera()


func _process(delta: float) -> void:
	_handle_keyboard_movement(delta)
	_handle_keyboard_rotation(delta)
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = max(_distance - zoom_speed, min_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = min(_distance + zoom_speed, max_distance)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_rotating = event.pressed
	
	if event is InputEventMouseMotion and _is_rotating:
		_yaw -= event.relative.x * 0.3
		_pitch = clamp(_pitch + event.relative.y * 0.3, 20.0, 80.0)


func _handle_keyboard_movement(delta: float) -> void:
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("camera_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("camera_back"):
		input_dir.y += 1
	if Input.is_action_pressed("camera_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("camera_right"):
		input_dir.x += 1
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		var speed = move_speed
		#if Input.is_action_pressed("camera_fast"):
			#speed *= fast_multiplier
		
		var forward = Vector3(sin(deg_to_rad(_yaw)), 0, cos(deg_to_rad(_yaw)))
		var right = Vector3(cos(deg_to_rad(_yaw)), 0, -sin(deg_to_rad(_yaw)))
		
		_target_position += (forward * input_dir.y + right * input_dir.x) * speed * delta


func _handle_keyboard_rotation(delta: float) -> void:
	if Input.is_action_pressed("camera_rotate_left"):
		_yaw += orbit_speed * delta
	if Input.is_action_pressed("camera_rotate_right"):
		_yaw -= orbit_speed * delta


func _update_camera() -> void:
	var yaw_rad = deg_to_rad(_yaw)
	var pitch_rad = deg_to_rad(_pitch)
	
	var offset = Vector3(
		sin(yaw_rad) * cos(pitch_rad),
		sin(pitch_rad),
		cos(yaw_rad) * cos(pitch_rad)
	) * _distance
	
	camera.global_position = _target_position + offset
	camera.look_at(_target_position, Vector3.UP)

func center_on_position(pos: Vector3, smooth: bool = true) -> void:
	if smooth:
		var tween = create_tween()
		tween.tween_property(self, "_target_position", Vector3(pos.x, 0, pos.z), 0.5).set_ease(Tween.EASE_OUT)
	else:
		_target_position = Vector3(pos.x, 0, pos.z)
