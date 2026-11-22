extends Resource
class_name DialogLine


@export var character: DialogManager.characters = DialogManager.characters.NONE

# Optional override for the speaker name in the dialogue box.

@export var speaker_name_override: String = ""

# Optional direct portrait texture 
@export var custom_portrait: Texture2D

# 2D coordinates on the sprite atlas if using a spritesheet
@export var portrait_coords: Vector2 = Vector2.ZERO 


@export_multiline var text: String = ""

# Portrait placement and visibility
enum Slot {
	DEFAULT,     
	LEFT_MAIN,   
	LEFT_SUB,     
	RIGHT_MAIN,    
	RIGHT_SUB,     
	HIDDEN         
}
@export var slot: Slot = Slot.DEFAULT

@export_group("Special Actions & FX")
# Visual effects: "shake", "slide_out", "wobble", "rise", "darken", "none"
@export var effect: String = ""
# Sound effect to play with this line 
@export var sfx: AudioStream
# Background music cue or trigger 
@export var music_cue: String = ""
# Animation to play on AnimationPlayer if any
@export var animation_name: String = ""
@export var visible: bool = true
