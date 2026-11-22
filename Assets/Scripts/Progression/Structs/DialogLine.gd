extends Resource
class_name DialogLine


@export var character: DialogManager.characters = DialogManager.characters.NONE

# Optional override for the speaker name in the dialogue box.

@export var speaker_name_override: String = ""

# Optional direct portrait texture 
@export var custom_portrait: Texture2D

# 2D coordinates on the sprite atlas if using a spritesheet
@export var portrait_coords: Vector2 = Vector2.ZERO 

# Portrait emotion, e.g. "neutral", "angry", "pained", "p2_furious". The outfit/form is picked from the story state.
@export var emotion: String = ""

# A second character shown with this line, standing behind the speaker (e.g. Keiki on a "Mayumi and Keiki" line)
@export var companion: DialogManager.characters = DialogManager.characters.NONE
@export var companion_emotion: String = ""


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
# In-world cutscene to play before this line, with the dialogue box hidden (e.g. "mayumi_enter", "saki_enter")
@export var cutscene_event: String = ""
@export var visible: bool = true
