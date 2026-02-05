extends Node

const Type = GameEnums.ResourceType

var resources: Dictionary = {
	Type.GOLD: 0,
	Type.FOOD: 0,
	Type.MATERIALS: 0
}


func _ready() -> void:
	resources[Type.GOLD] = ConfigManager.config.starting_gold
	resources[Type.FOOD] = ConfigManager.config.starting_food
	resources[Type.MATERIALS] = ConfigManager.config.starting_materials
	
	GameManager.register_resource_manager(self)


func get_amount(type: GameEnums.ResourceType) -> int:
	return resources.get(type, 0)


func add(type: GameEnums.ResourceType, amount: int) -> void:
	resources[type] += amount
	EventBus.resources_changed.emit(type, resources[type])


func spend_type(type: GameEnums.ResourceType, amount: int) -> bool:
	if resources[type] < amount:
		return false
	resources[type] -= amount
	EventBus.resources_changed.emit(type, resources[type])
	
	if resources[type] <= 0:
		EventBus.resource_depleted.emit(type)
	
	return true


func can_afford(district: DistrictData) -> bool:
	return (
		resources[Type.GOLD] >= district.gold_cost and
		resources[Type.FOOD] >= district.food_cost and
		resources[Type.MATERIALS] >= district.materials_cost
	)


func spend(district: DistrictData) -> bool:
	if not can_afford(district):
		return false
	
	spend_type(Type.GOLD, district.gold_cost)
	spend_type(Type.FOOD, district.food_cost)
	spend_type(Type.MATERIALS, district.materials_cost)
	return true


func apply_production(district: DistrictData) -> void:
	add(Type.GOLD, district.gold_production)
	add(Type.FOOD, district.food_production)
	add(Type.MATERIALS, district.materials_production)


func apply_consumption(district: DistrictData) -> bool:
	if not _can_afford_consumption(district):
		return false
	
	spend_type(Type.GOLD, district.gold_consumption)
	spend_type(Type.FOOD, district.food_consumption)
	spend_type(Type.MATERIALS, district.materials_consumption)
	return true


func _can_afford_consumption(district: DistrictData) -> bool:
	return (
		resources[Type.GOLD] >= district.gold_consumption and
		resources[Type.FOOD] >= district.food_consumption and
		resources[Type.MATERIALS] >= district.materials_consumption
	)


func get_gold() -> int:
	return resources[Type.GOLD]


func get_food() -> int:
	return resources[Type.FOOD]


func get_materials() -> int:
	return resources[Type.MATERIALS]
