extends Node
class_name CeramicSkinProxy

@export_group("Sprite Textures")
@export var sprites_to_replace: Array[Sprite2D] = []
@export var ceramic_textures: Array[Texture2D] = []

@export_group("Polygon Textures")
@export var polygons_to_replace: Array[Polygon2D] = []
@export var ceramic_polygon_textures: Array[Texture2D] = []

@export_group("Shader Removal")
@export var sprites_to_remove_shader: Array[CanvasItem] = []


func apply_ceramic_skin() -> void:
	# Replace Sprite2D textures.
	if sprites_to_replace.size() != ceramic_textures.size():
		push_warning("CeramicSkinProxy: Sprite and texture arrays must have matching sizes.")
	else:
		for i in range(sprites_to_replace.size()):
			var sprite := sprites_to_replace[i]
			if is_instance_valid(sprite) and ceramic_textures[i] != null:
				sprite.texture = ceramic_textures[i]

	# Replace Polygon2D textures.
	if polygons_to_replace.size() != ceramic_polygon_textures.size():
		push_warning("CeramicSkinProxy: Polygon and texture arrays must have matching sizes.")
	else:
		for i in range(polygons_to_replace.size()):
			var polygon := polygons_to_replace[i]
			if is_instance_valid(polygon) and ceramic_polygon_textures[i] != null:
				polygon.texture = ceramic_polygon_textures[i]

	# Remove shaders.
	for sprite in sprites_to_remove_shader:
		if is_instance_valid(sprite):
			sprite.material = null
