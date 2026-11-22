extends Resource
class_name DialogStruct

# Ordered lines of dialogue for this scene
@export var dialog_lines: Array[DialogLine] = []

# If non-empty, one variant is chosen at random when this dialogue is played (e.g. for scenes A1-F, A1-G, A3-D)
@export var variants: Array[DialogStruct] = []

# Optional background texture for this dialogue scene (e.g. Bridge, Kiln)
@export var background: Texture2D


func get_effective_lines() -> Array[DialogLine]:
	if not variants.is_empty():
		var chosen: DialogStruct = variants.pick_random()
		if chosen != null:
			return chosen.get_effective_lines()

	return dialog_lines
