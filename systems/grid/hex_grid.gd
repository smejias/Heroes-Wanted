@tool
class_name HexGrid
extends Node3D

@export var grid_radius: int = 5
@export var hex_size: float = 1.0
@export var tile_scene: PackedScene
@export var default_terrain: PackedScene

@export_group("Editor Actions")
@export_tool_button("Generate Grid") var generate_action: Callable = generate
@export_tool_button("Clear Grid") var clear_action: Callable = clear

var tiles: Dictionary = {}


func _ready() -> void:
	if not Engine.is_editor_hint():
		_rebuild_tiles_dictionary()


func _rebuild_tiles_dictionary() -> void:
	tiles.clear()
	for child in get_children():
		if child is Tile:
			tiles[child.coord] = child


func generate() -> void:
	clear()
	
	if not tile_scene:
		push_error("Assign tile_scene first")
		return
	
	for q in range(-grid_radius, grid_radius + 1):
		for r in range(-grid_radius, grid_radius + 1):
			var s = -q - r
			if abs(s) > grid_radius:
				continue
			
			var coord = Vector3i(q, r, s)
			_create_tile(coord)
	
	print("Generated ", tiles.size(), " tiles")


func _create_tile(coord: Vector3i) -> void:
	var tile = tile_scene.instantiate() as Tile
	tile.name = "Tile_%d_%d_%d" % [coord.x, coord.y, coord.z]
	tile.coord = coord
	tile.position = _cube_to_world(coord)
	
	if default_terrain:
		tile.terrain_scene = default_terrain
	
	add_child(tile, true)
	tile.owner = get_tree().edited_scene_root
	
	tiles[coord] = tile


func _cube_to_world(coord: Vector3i) -> Vector3:
	var x = hex_size * 1.5 * coord.x
	var z = hex_size * sqrt(3.0) * (coord.x * 0.5 + coord.z)
	return Vector3(x, 0, z)


func clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	tiles.clear()
	print("Cleared grid")


func get_tile(coord: Vector3i) -> Tile:
	return tiles.get(coord)


func get_all_tiles() -> Array[Tile]:
	var result: Array[Tile] = []
	for tile in tiles.values():
		result.append(tile)
	return result


func get_built_tiles() -> Array[Tile]:
	var result: Array[Tile] = []
	for tile in tiles.values():
		if tile.state == GameEnums.TileState.BUILT:
			result.append(tile)
	return result


func get_buildable_tiles() -> Array[Tile]:
	var buildable_coords: Dictionary = {}
	
	for tile in get_built_tiles():
		var radius = tile.get_build_radius()
		if radius <= 0:
			continue
		
		var coords_in_radius = HexUtils.get_range(tile.coord, radius)
		for coord in coords_in_radius:
			buildable_coords[coord] = true
	
	var result: Array[Tile] = []
	for coord in buildable_coords.keys():
		var tile = get_tile(coord)
		if tile and tile.state == GameEnums.TileState.EMPTY and tile.can_build:
			result.append(tile)
	
	return result


func highlight_buildable_tiles() -> void:
	clear_all_highlights()
	for tile in get_buildable_tiles():
		tile.highlight(true)


func clear_all_highlights() -> void:
	for tile in tiles.values():
		tile.clear_highlight()
