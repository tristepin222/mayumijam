extends CanvasLayer
class_name DialogPlayer

signal dialog_finished

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

const character_names = ["Mayumi", "Saki", "Keiki"]

const dialog_files = {
	situations.INTRO: "res://Assets/Scripts/Presentation/DialogueLines/IntroDialogue.tres",
	situations.SAKITAUNT: "res://Assets/Scripts/Presentation/DialogueLines/SakiTauntDialogue.tres",
	situations.MAYUMILOSE: "res://Assets/Scripts/Presentation/DialogueLines/MayumiLoseDialogue.tres",
	situations.MAYUMIWIN: "res://Assets/Scripts/Presentation/DialogueLines/MayumiWinDialogue.tres",
	situations.KEIKIUPGRADE: "res://Assets/Scripts/Presentation/DialogueLines/KeikiUpgradeDialogue.tres",
}

const speaking_color = Color(1, 1, 1, 1)
const silent_color = Color(0.49019608, 0.49019608, 0.49019608, 1)

const text_color = Color(0.12, 0.1, 0.16)
const name_color = "#6b2a8a"
const text_font_size = 20
const portrait_height_ratio = 0.78
const dim_color = Color(0, 0, 0, 0.55)

var dialog_opened = false
var current_dialog_pos: int = 0 #position in the dialogue

var current_dialog_resource: DialogStruct

const sprite_size = 1000

var dim_rect: ColorRect


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialog_text.bbcode_enabled = true
	dialog_text.add_theme_color_override("default_color", text_color)
	dialog_text.add_theme_font_size_override("normal_font_size", text_font_size)
	dialog_text.add_theme_font_size_override("bold_font_size", text_font_size + 2)

	dim_rect = ColorRect.new()
	dim_rect.color = dim_color
	dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.visible = false
	add_child(dim_rect)
	move_child(dim_rect, 0)

	_layout_portraits()
	get_viewport().size_changed.connect(_layout_portraits)


func _layout_portraits():
	var view_size := get_viewport().get_visible_rect().size
	var height := view_size.y * portrait_height_ratio

	for i in range(sprites.size()):
		var sprite := sprites[i] as TextureRect
		sprite.scale = Vector2.ONE
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.set_anchors_preset(Control.PRESET_TOP_LEFT)
		sprite.size = Vector2(height, height)

		var x := 0.0 if i == character.MAYUMI else view_size.x - height
		sprite.position = Vector2(x, view_size.y - height)


func play_dialog(new_script: situations) -> void:
	_open_dialog(new_script)

	if dialog_opened:
		await dialog_finished


func _open_dialog(new_script: situations):
	_get_dialog(new_script)

	if current_dialog_resource == null or current_dialog_resource.dialog_text.is_empty():
		return

	current_dialog_pos = 0

	for i in range(sprites.size()):
		sprites[i].visible = current_dialog_resource.characters.has(i)

	_update_dialog(current_dialog_pos)
	dialog_opened = true
	dim_rect.visible = true
	$sprite_dialog.visible = true

	if dialog_animation.has_animation("DialogOpenAnim"):
		dialog_animation.play("DialogOpenAnim")

func _update_dialog(new_dialog_pos):
	var speaker: int = current_dialog_resource.characters[new_dialog_pos]

	for i in range(sprites.size()):
		sprites[i].self_modulate = speaking_color if i == speaker else silent_color

	var sprite := sprites[speaker] as TextureRect
	var atlas := sprite.texture as AtlasTexture

	if atlas != null and atlas.atlas != null:
		var sheet_size := atlas.atlas.get_size()

		if sheet_size.x >= sprite_size * 2 or sheet_size.y >= sprite_size * 2:
			if new_dialog_pos < current_dialog_resource.atlas_index_x.size():
				atlas.region = Rect2(current_dialog_resource.atlas_index_x[new_dialog_pos] * sprite_size, current_dialog_resource.atlas_index_y[new_dialog_pos] * sprite_size, sprite_size, sprite_size)
		else:
			atlas.region = Rect2(Vector2.ZERO, sheet_size)

	dialog_text.text = "[b][color=%s]%s[/color][/b]\n%s" % [name_color, character_names[speaker], current_dialog_resource.dialog_text[new_dialog_pos]]

func _continue_dialog():
	if current_dialog_pos + 1 < current_dialog_resource.characters.size():
		current_dialog_pos +=1
		_update_dialog(current_dialog_pos)
	else:
		_close_dialog()

func _close_dialog():
	dialog_opened = false

	if dialog_animation.has_animation("DialogCloseAnim"):
		dialog_animation.play("DialogCloseAnim")
		await dialog_animation.animation_finished

	dim_rect.visible = false
	$sprite_dialog.visible = false

	for sprite in sprites:
		sprite.visible = false

	dialog_finished.emit()

#Use enum to select a resource file containing a dialogue data.
func _get_dialog(new_script_enum: DialogManager.situations):
	current_dialog_resource = null

	if dialog_files.has(new_script_enum) and ResourceLoader.exists(dialog_files[new_script_enum]):
		current_dialog_resource = load(dialog_files[new_script_enum]) as DialogStruct


func _input(event: InputEvent):
	if not dialog_opened:
		return

	if event.is_action_pressed("update_dialog") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_continue_dialog()
