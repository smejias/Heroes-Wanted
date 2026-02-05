@tool
class_name Tile
extends Node3D

@export var coord: Vector3i
@export var terrain_type: GameEnums.TerrainType = GameEnums.TerrainType.GRASSLAND
@export var can_build: bool = true
@export var terrain_scene: PackedScene:
	set(value):
		terrain_scene = value
		_update_terrain()
		_detect_terrain_type()

var state: GameEnums.TileState = GameEnums.TileState.EMPTY
var district_data: DistrictData = null
var district_instance: Node3D = null
var construction_timer: float = 0.0

var _terrain_instance: Node3D = null
var _highlight_material: StandardMaterial3D

@onready var terrain_anchor: Node3D = $TerrainAnchor
@onready var district_anchor: Node3D = $DistrictAnchor


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("tiles")
		#if state == GameEnums.TileState.BUILT and district_data:
			#_spawn_influence_area()
	_update_terrain()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if state == GameEnums.TileState.UNDER_CONSTRUCTION:
		construction_timer -= delta
		if construction_timer <= 0:
			_complete_construction()


func _detect_terrain_type() -> void:
	if not terrain_scene:
		return
	
	var path = terrain_scene.resource_path.to_lower()
	
	if "water" in path:
		terrain_type = GameEnums.TerrainType.WATER
		can_build = false
	elif "mountain" in path:
		terrain_type = GameEnums.TerrainType.MOUNTAIN
		can_build = false
	elif "forest" in path:
		terrain_type = GameEnums.TerrainType.FOREST
		can_build = true
	else:
		terrain_type = GameEnums.TerrainType.GRASSLAND
		can_build = true


func _update_terrain() -> void:
	if _terrain_instance:
		_terrain_instance.queue_free()
		_terrain_instance = null
	
	if not terrain_scene:
		return
	
	var anchor = get_node_or_null("TerrainAnchor")
	if not anchor:
		return
	
	_terrain_instance = terrain_scene.instantiate()
	anchor.add_child(_terrain_instance)
	
	if Engine.is_editor_hint() and is_inside_tree():
		var tree = get_tree()
		if tree and tree.edited_scene_root:
			_terrain_instance.owner = tree.edited_scene_root
		_set_not_selectable_recursive(_terrain_instance)


func _set_not_selectable_recursive(node: Node) -> void:
	if node is Node3D:
		node.set_meta("_edit_lock_", true)
	for child in node.get_children():
		_set_not_selectable_recursive(child)


func start_construction(data: DistrictData) -> void:
	if Engine.is_editor_hint():
		return
	if state != GameEnums.TileState.EMPTY or not can_build:
		return
	
	district_data = data
	construction_timer = data.construction_time
	state = GameEnums.TileState.UNDER_CONSTRUCTION
	EventBus.construction_started.emit(self, data)


func _complete_construction() -> void:
	state = GameEnums.TileState.BUILT
	_spawn_district()
	#_spawn_influence_area()
	EventBus.construction_completed.emit(self, district_data)


func _spawn_district() -> void:
	if district_data and district_data.scene:
		district_instance = district_data.scene.instantiate()
		district_anchor.add_child(district_instance)

func disable() -> void:
	if state == GameEnums.TileState.BUILT:
		state = GameEnums.TileState.DISABLED
		EventBus.district_disabled.emit(self)


func damage() -> void:
	state = GameEnums.TileState.DAMAGED
	EventBus.district_damaged.emit(self)


func repair() -> void:
	if state == GameEnums.TileState.DAMAGED:
		state = GameEnums.TileState.BUILT
		EventBus.district_repaired.emit(self)


func get_build_radius() -> int:
	if district_data and state == GameEnums.TileState.BUILT:
		return district_data.build_radius
	return 0


func highlight(valid: bool = true) -> void:
	if Engine.is_editor_hint():
		return
	
	if not _highlight_material:
		_highlight_material = StandardMaterial3D.new()
		_highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var mat = _highlight_material.duplicate() as StandardMaterial3D
	mat.albedo_color = Color(0.2, 0.8, 0.2, 0.5) if valid else Color(0.8, 0.2, 0.2, 0.5)
	
	var mesh = _get_terrain_mesh()
	if mesh:
		mesh.material_overlay = mat


func clear_highlight() -> void:
	if Engine.is_editor_hint():
		return
	
	var mesh = _get_terrain_mesh()
	if mesh:
		mesh.material_overlay = null


func _get_terrain_mesh() -> MeshInstance3D:
	var anchor = get_node_or_null("TerrainAnchor")
	if not anchor:
		return null
	
	return _find_mesh_recursive(anchor)


func _find_mesh_recursive(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		var result = _find_mesh_recursive(child)
		if result:
			return result
	return null
