extends CanvasLayer

@onready var gold_label: Label = %GoldLabel
@onready var food_label: Label = %FoodLabel
@onready var materials_label: Label = %MaterialsLabel
@onready var day_label: Label = %DayLabel
@onready var time_label: Label = %TimeLabel
@onready var population_label: Label = %PopulationLabel
@onready var build_panel: Control = %BuildPanel
@onready var build_mode_button: Button = %BuildModeButton
@onready var speed_label: Label = %SpeedLabel


func _ready() -> void:
	EventBus.resources_changed.connect(_on_resources_changed)
	EventBus.day_started.connect(_on_day_started)
	EventBus.build_mode_entered.connect(_on_build_mode_entered)
	EventBus.build_mode_exited.connect(_on_build_mode_exited)
	EventBus.population_changed.connect(_on_population_changed)
	EventBus.time_scale_changed.connect(_on_time_scale_changed)
	

	
	build_mode_button.pressed.connect(_on_build_mode_pressed)
		
	build_panel.visible = false
	_update_all_resources()
	_update_day(TimeManager.get_day())
	_update_population(PopulationManager.get_population(), PopulationManager.get_max_population())
	_update_speed(1.0)


func _process(_delta: float) -> void:
	time_label.text = TimeManager.get_formatted_time()


func _update_all_resources() -> void:
	gold_label.text = str(ResourceManager.get_gold())
	food_label.text = str(ResourceManager.get_food())
	materials_label.text = str(ResourceManager.get_materials())


func _on_resources_changed(type: int, amount: int) -> void:
	match type:
		GameEnums.ResourceType.GOLD:
			gold_label.text = str(amount)
		GameEnums.ResourceType.FOOD:
			food_label.text = str(amount)
		GameEnums.ResourceType.MATERIALS:
			materials_label.text = str(amount)


func _on_day_started(day: int) -> void:
	_update_day(day)


func _update_day(day: int) -> void:
	day_label.text = "Day %d" % day


func _on_build_mode_entered() -> void:
	build_panel.visible = true
	build_mode_button.text = "Exit Build"


func _on_build_mode_exited() -> void:
	build_panel.visible = false
	build_mode_button.text = "Build (B)"


func _on_build_mode_pressed() -> void:
	if GameManager.current_state_name == "build":
		GameManager.change_state("play")
	else:
		GameManager.change_state("build")


func _on_population_changed(current: int, max_pop: int) -> void:
	_update_population(current, max_pop)


func _update_population(current: int, max_pop: int) -> void:
	population_label.text = "%d / %d" % [current, max_pop]
	
	if current > max_pop:
		population_label.add_theme_color_override("font_color", Color.RED)
	elif current < max_pop * 0.3:
		population_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		population_label.remove_theme_color_override("font_color")

func _on_time_scale_changed(scale: float) -> void:
	_update_speed(scale)


func _update_speed(scale: float) -> void:
	if scale == 1.0:
		speed_label.text = "▶"
	else:
		speed_label.text = "▶▶ x%d" % int(scale)
