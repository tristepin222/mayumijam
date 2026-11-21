extends CanvasLayer
class_name DialogPlayer

@onready var player_sprite = $player_sprite as TextureRect
@onready var saki_sprite = $saki_sprite as TextureRect
@onready var keiki_sprite = $keiki_sprite as TextureRect
@onready var dialog_text = $sprite_dialog/text_dialog as RichTextLabel
@onready var  dialog_animation = $anim_dialog as AnimationPlayer

@onready var sprites = [player_sprite, saki_sprite, keiki_sprite]

var dialog_character = [
	preload("res://Assets/Textures/PlaceHolders/UI/Portaits/Mayumi/Mayumi Ghost Neutral.png").get_image(),
	preload("res://Assets/Textures/PlaceHolders/UI/ran_sprite_sheet.png").get_image(),
]

#Enum from the DialogManager
const situations = DialogManager.situations
const character = DialogManager.characters

var dialog_opened = false
var current_dialog_pos: int = 0 #position in the dialogue

var current_dialog_resource = []

const sprite_size = 1000

func _open_dialog(new_script: situations):
	_get_dialog(new_script)
	current_dialog_pos = 0
	_update_dialog(current_dialog_pos)
	dialog_opened = true
	dialog_animation.play("DialogOpenAnim")

func _update_dialog(new_dialog_pos):
	sprites[new_dialog_pos].texture.region = Rect2(current_dialog_resource.atlas_index_x[new_dialog_pos] * sprite_size, current_dialog_resource.atlas_index_y[new_dialog_pos] * sprite_size, sprite_size, sprite_size)
	dialog_text.text = current_dialog_resource.dialog_text[new_dialog_pos]

func _continue_dialog():
	if current_dialog_pos + 1 < current_dialog_resource.characters.size():
		current_dialog_pos +=1
		_update_dialog(current_dialog_pos) 
	else: 
		_close_dialog()

func _close_dialog():
	dialog_opened = false

#Use enum to select a resource file containing a dialogue data.
func _get_dialog(new_script_enum: DialogManager.situations):
	match new_script_enum:
		situations.INTRO: 
			current_dialog_resource = load("res://Assets/Scripts/Presentation/DialogueLines/IntroDialogue.tres")
		
#DEBUG

func _input(event: InputEvent):
	if event.is_action_pressed("update_dialog"):
		if !dialog_opened:
			_open_dialog(self.situations.INTRO)
		else:
			_continue_dialog()
