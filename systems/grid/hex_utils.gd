class_name HexUtils

# Cube coordinate directions (flat-top)
const DIRECTIONS: Array[Vector3i] = [
	Vector3i(1, -1, 0),  # East
	Vector3i(1, 0, -1),  # Southeast
	Vector3i(0, 1, -1),  # Southwest
	Vector3i(-1, 1, 0),  # West
	Vector3i(-1, 0, 1),  # Northwest
	Vector3i(0, -1, 1),  # Northeast
]


static func get_neighbors(cube: Vector3i) -> Array[Vector3i]:
	var neighbors: Array[Vector3i] = []
	for dir in DIRECTIONS:
		neighbors.append(cube + dir)
	return neighbors


static func get_neighbor(cube: Vector3i, direction: int) -> Vector3i:
	return cube + DIRECTIONS[direction % 6]


static func distance(a: Vector3i, b: Vector3i) -> int:
	var diff = a - b
	return (abs(diff.x) + abs(diff.y) + abs(diff.z)) / 2


static func get_range(center: Vector3i, radius: int) -> Array[Vector3i]:
	var results: Array[Vector3i] = []
	for q in range(-radius, radius + 1):
		for r in range(max(-radius, -q - radius), min(radius, -q + radius) + 1):
			var s = -q - r
			results.append(center + Vector3i(q, r, s))
	return results


static func get_ring(center: Vector3i, radius: int) -> Array[Vector3i]:
	if radius == 0:
		return [center]
	
	var results: Array[Vector3i] = []
	var cube = center + DIRECTIONS[4] * radius  # Start at Northwest * radius
	
	for i in range(6):
		for j in range(radius):
			results.append(cube)
			cube = get_neighbor(cube, i)
	
	return results


static func lerp_cube(a: Vector3i, b: Vector3i, t: float) -> Vector3:
	return Vector3(
		lerpf(a.x, b.x, t),
		lerpf(a.y, b.y, t),
		lerpf(a.z, b.z, t)
	)


static func cube_round(cube: Vector3) -> Vector3i:
	var q = round(cube.x)
	var r = round(cube.y)
	var s = round(cube.z)
	
	var q_diff = abs(q - cube.x)
	var r_diff = abs(r - cube.y)
	var s_diff = abs(s - cube.z)
	
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	else:
		s = -q - r
	
	return Vector3i(int(q), int(r), int(s))


static func line(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var n = distance(a, b)
	if n == 0:
		return [a]
	
	var results: Array[Vector3i] = []
	for i in range(n + 1):
		results.append(cube_round(lerp_cube(a, b, float(i) / n)))
	return results


# Flat-top hex: q = column, r = row offset
static func cube_to_world(cube: Vector3i, hex_size: float) -> Vector3:
	var x = hex_size * 1.5 * cube.x
	var z = hex_size * sqrt(3.0) * (cube.x * 0.5 + cube.z)
	return Vector3(x, 0, z)


static func world_to_cube(world_pos: Vector3, hex_size: float) -> Vector3i:
	var q = (2.0 / 3.0 * world_pos.x) / hex_size
	var r = (-1.0 / 3.0 * world_pos.x + sqrt(3.0) / 3.0 * world_pos.z) / hex_size
	return cube_round(Vector3(q, -q - r, r))


static func is_valid(cube: Vector3i) -> bool:
	return cube.x + cube.y + cube.z == 0
