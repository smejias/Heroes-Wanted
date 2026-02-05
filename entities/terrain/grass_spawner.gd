extends Node3D

@export var density: int = 1000
@export var hex_radius: float = 1.1

var grass_material: ShaderMaterial

func _ready() -> void:
	_setup_material()
	_spawn_grass()

func _setup_material() -> void:
	grass_material = ShaderMaterial.new()
	grass_material.shader = preload("res://assets/shaders/grass/grass_blade_shader.gdshader")
	
	var noise := NoiseTexture2D.new()
	noise.noise = FastNoiseLite.new()
	grass_material.set_shader_parameter("noise_tex", noise)

func _spawn_grass() -> void:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	
	mm.mesh = _create_blade_mesh()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = density
	
	for i in density:
		var pos := _random_hex_point()
		var t := Transform3D()
		t = t.rotated(Vector3.UP, randf() * TAU)
		t = t.scaled(Vector3.ONE * randf_range(0.7, 1.3))
		t.origin = pos
		mm.set_instance_transform(i, t)
	
	mmi.multimesh = mm
	mmi.material_override = grass_material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

func _is_inside_hex(x: float, z: float) -> bool:
	var ax := absf(x)
	var az := absf(z)
	
	# Flat-top: lados planos en X, puntas en Z
	if ax > hex_radius:
		return false
	
	if az + ax / sqrt(3.0) > hex_radius * sqrt(3.0) / 2.0:
		return false
	
	return true

func _random_hex_point() -> Vector3:
	var width := hex_radius
	var height := hex_radius * sqrt(3.0) / 2.0
	while true:
		var x := randf_range(-width, width)
		var z := randf_range(-height, height)
		if _is_inside_hex(x, z):
			return Vector3(x, 0.0, z)
	return Vector3.ZERO

func _create_blade_mesh() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var verts := PackedVector3Array([
		Vector3(-0.03, 0.0, 0.0),
		Vector3(0.03, 0.0, 0.0),
		Vector3(0.02, 0.1, 0.0),
		Vector3(-0.02, 0.1, 0.0),
		Vector3(0.0, 0.2, 0.0),
	])
	var uvs := PackedVector2Array([
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(1.0, 0.5),
		Vector2(0.0, 0.5),
		Vector2(0.5, 0.0),
	])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3, 3, 2, 4])
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
