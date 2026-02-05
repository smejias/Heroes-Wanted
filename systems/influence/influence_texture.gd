@tool
class_name InfluenceTexture
extends Resource

@export var size: int = 256
@export var color: Color = Color(0.3, 0.6, 1.0, 0.4)
@export_tool_button("Generate") var generate_action: Callable = generate

var texture: ImageTexture


func generate() -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var max_dist = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var alpha = 1.0 - clamp(dist / max_dist, 0.0, 1.0)
			alpha = alpha * alpha * color.a
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	texture = ImageTexture.create_from_image(image)
	print("Texture generated")
	return texture
