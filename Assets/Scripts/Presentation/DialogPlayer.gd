extends CanvasLayer
class_name DialogPlayer

signal dialog_finished
signal dialog_line_started(line: DialogLine)
signal music_cue_requested(cue_name: String)

@onready var player_sprite = $player_sprite as TextureRect
@onready var saki_sprite = $saki_sprite as TextureRect
@onready var keiki_sprite = $keiki_sprite as TextureRect
@onready var dialog_text = $sprite_dialog/text_dialog as RichTextLabel
@onready var dialog_animation = $anim_dialog as AnimationPlayer

@onready var sprites = [player_sprite, saki_sprite, keiki_sprite]

var sfx_player: AudioStreamPlayer

# Enums from DialogManager
const situations = DialogManager.situations
const character = DialogManager.characters

const character_names = ["Mayumi", "Saki", "Keiki"]

const dialog_files = {
	# Act 1
	situations.A1_INTRO: "res://Assets/Scripts/Presentation/DialogueLines/A1_Intro.tres",
	situations.A1_A: "res://Assets/Scripts/Presentation/DialogueLines/A1_A.tres",
	situations.A1_B: "res://Assets/Scripts/Presentation/DialogueLines/A1_B.tres",
	situations.A1_C_PRE: "res://Assets/Scripts/Presentation/DialogueLines/A1_C_Pre.tres",
	situations.A1_C_POST: "res://Assets/Scripts/Presentation/DialogueLines/A1_C_Post.tres",
	situations.A1_D: "res://Assets/Scripts/Presentation/DialogueLines/A1_D.tres",
	situations.A1_E_PRE: "res://Assets/Scripts/Presentation/DialogueLines/A1_E_Pre.tres",
	situations.A1_E_POST: "res://Assets/Scripts/Presentation/DialogueLines/A1_E_Post.tres",
	situations.A1_F: "res://Assets/Scripts/Presentation/DialogueLines/A1_F.tres",
	situations.A1_G: "res://Assets/Scripts/Presentation/DialogueLines/A1_G.tres",
	situations.A1_H: "res://Assets/Scripts/Presentation/DialogueLines/A1_H.tres",

	# Act 2
	situations.A2_A: "res://Assets/Scripts/Presentation/DialogueLines/A2_A.tres",
	situations.A2_B: "res://Assets/Scripts/Presentation/DialogueLines/A2_B.tres",
	situations.A2_C: "res://Assets/Scripts/Presentation/DialogueLines/A2_C.tres",
	situations.A2_D_PRE: "res://Assets/Scripts/Presentation/DialogueLines/A2_D_Pre.tres",
	situations.A2_D_POST: "res://Assets/Scripts/Presentation/DialogueLines/A2_D_Post.tres",
	situations.A2_E: "res://Assets/Scripts/Presentation/DialogueLines/A2_E.tres",
	situations.A2_F: "res://Assets/Scripts/Presentation/DialogueLines/A2_F.tres",
	situations.A2_G: "res://Assets/Scripts/Presentation/DialogueLines/A2_G.tres",
	situations.A2_H_PRE: "res://Assets/Scripts/Presentation/DialogueLines/A2_H_Pre.tres",
	situations.A2_H_POST: "res://Assets/Scripts/Presentation/DialogueLines/A2_H_Post.tres",

	# Act 3
	situations.A3_A: "res://Assets/Scripts/Presentation/DialogueLines/A3_A.tres",
	situations.A3_B: "res://Assets/Scripts/Presentation/DialogueLines/A3_B.tres",
	situations.A3_C: "res://Assets/Scripts/Presentation/DialogueLines/A3_C.tres",
	situations.A3_D: "res://Assets/Scripts/Presentation/DialogueLines/A3_D.tres",
	situations.A3_E_PRE: "res://Assets/Scripts/Presentation/DialogueLines/A3_E_Pre.tres",
	situations.A3_E_POST: "res://Assets/Scripts/Presentation/DialogueLines/A3_E_Post.tres",
	situations.A3_F: "res://Assets/Scripts/Presentation/DialogueLines/A3_F.tres",

	# Endings
	situations.ENDING_1: "res://Assets/Scripts/Presentation/DialogueLines/Ending1.tres",
	situations.ENDING_2: "res://Assets/Scripts/Presentation/DialogueLines/Ending2.tres",
	situations.ENDING_3: "res://Assets/Scripts/Presentation/DialogueLines/Ending3.tres",
}

const speaking_color = Color(1, 1, 1, 1)
const silent_color = Color(0.49, 0.49, 0.49, 1)

const text_color = Color(0.12, 0.1, 0.16)
const name_color = "#6b2a8a"
const text_font_size = 20
const portrait_height_ratio = 0.78
const dim_color = Color(0, 0, 0, 0.55)

var dialog_opened = false
var current_dialog_pos: int = 0
var current_dialog_resource: DialogStruct
var active_lines: Array[DialogLine] = []

const sprite_size = 1000

var dim_rect: ColorRect
var base_textures: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	dialog_text.bbcode_enabled = true
	dialog_text.add_theme_color_override("default_color", text_color)
	dialog_text.add_theme_font_size_override("normal_font_size", text_font_size)
	dialog_text.add_theme_font_size_override("bold_font_size", text_font_size + 2)

	# Setup SFX player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "dialog_sfx_player"
	sfx_player.bus = "Master"
	add_child(sfx_player)

	# Store initial base textures
	base_textures[player_sprite] = player_sprite.texture
	base_textures[saki_sprite] = saki_sprite.texture
	base_textures[keiki_sprite] = keiki_sprite.texture

	# Dimming rect
	dim_rect = ColorRect.new()
	dim_rect.color = dim_color
	dim_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim_rect.visible = false
	add_child(dim_rect)
	move_child(dim_rect, 0)

	_layout_portraits()
	get_viewport().size_changed.connect(_layout_portraits)


func _layout_portraits() -> void:
	var view_size := get_viewport().get_visible_rect().size
	var height := view_size.y * portrait_height_ratio

	for sprite in sprites:
		var tex_rect := sprite as TextureRect
		tex_rect.scale = Vector2.ONE
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.size = Vector2(height, height)


func _get_slot_position(slot: DialogLine.Slot, char_id: int, has_saki_present: bool) -> Vector2:
	var view_size := get_viewport().get_visible_rect().size
	var height := view_size.y * portrait_height_ratio

	match slot:
		DialogLine.Slot.LEFT_MAIN:
			return Vector2(0.0, view_size.y - height)
		DialogLine.Slot.LEFT_SUB:
			return Vector2(height * 0.35, view_size.y - height)
		DialogLine.Slot.RIGHT_MAIN:
			return Vector2(view_size.x - height, view_size.y - height)
		DialogLine.Slot.RIGHT_SUB:
			return Vector2(view_size.x - height * 1.35, view_size.y - height)
		DialogLine.Slot.DEFAULT, _:
			if char_id == character.MAYUMI:
				return Vector2(0.0, view_size.y - height)
			elif char_id == character.SAKI:
				return Vector2(view_size.x - height, view_size.y - height)
			elif char_id == character.KEIKI:
				# If Saki is present in the scene, Keiki stands with Mayumi on the left
				if has_saki_present:
					return Vector2(height * 0.35, view_size.y - height)
				else:
					# Otherwise (workshop with Mayumi), Keiki is on the right
					return Vector2(view_size.x - height, view_size.y - height)
			return Vector2(0.0, view_size.y - height)


func play_dialog(new_script: int) -> void:
	_open_dialog(new_script)
	if dialog_opened:
		await dialog_finished


func play_dialog_resource(dialog_resource: DialogStruct) -> void:
	_open_dialog_resource(dialog_resource)
	if dialog_opened:
		await dialog_finished


func _open_dialog(new_script: int) -> void:
	var res := _get_dialog_resource(new_script)
	if res == null:
		push_warning("DialogPlayer: No dialog found for situation %s" % new_script)
		return
	_open_dialog_resource(res)


func _open_dialog_resource(res: DialogStruct) -> void:
	current_dialog_resource = res
	active_lines = current_dialog_resource.get_effective_lines()

	if active_lines.is_empty():
		return

	current_dialog_pos = 0

	# Check which characters appear anywhere in this scene
	var has_mayumi: bool = false
	var has_saki: bool = false
	var has_keiki: bool = false

	for line in active_lines:
		if line.character == character.MAYUMI:
			has_mayumi = true
		elif line.character == character.SAKI:
			has_saki = true
		elif line.character == character.KEIKI:
			has_keiki = true

	player_sprite.visible = has_mayumi
	saki_sprite.visible = has_saki
	keiki_sprite.visible = has_keiki

	# Position sprites
	player_sprite.position = _get_slot_position(DialogLine.Slot.LEFT_MAIN, character.MAYUMI, has_saki)
	saki_sprite.position = _get_slot_position(DialogLine.Slot.RIGHT_MAIN, character.SAKI, has_saki)
	keiki_sprite.position = _get_slot_position(DialogLine.Slot.DEFAULT, character.KEIKI, has_saki)

	# Z-indexing so left sub is behind left main
	player_sprite.z_index = 3
	keiki_sprite.z_index = 2 if has_saki else 3
	saki_sprite.z_index = 3

	_update_dialog(current_dialog_pos)
	dialog_opened = true
	dim_rect.visible = true
	$sprite_dialog.visible = true

	if dialog_animation.has_animation("DialogOpenAnim"):
		dialog_animation.play("DialogOpenAnim")


func _update_dialog(new_dialog_pos: int) -> void:
	if new_dialog_pos >= active_lines.size():
		_close_dialog()
		return

	var line: DialogLine = active_lines[new_dialog_pos]
	var speaker: int = line.character
	var has_saki: bool = saki_sprite.visible if saki_sprite != null else false

	# Emit line started signal
	dialog_line_started.emit(line)

	# Update modulates based on who is speaking
	for i in range(sprites.size()):
		sprites[i].self_modulate = speaking_color if i == speaker else silent_color

	# Determine active sprite
	var active_sprite: TextureRect = null
	if speaker == character.MAYUMI:
		active_sprite = player_sprite
	elif speaker == character.SAKI:
		active_sprite = saki_sprite
	elif speaker == character.KEIKI:
		active_sprite = keiki_sprite

	# Custom portrait or atlas update
	if active_sprite != null:
		if line.custom_portrait != null:
			active_sprite.texture = line.custom_portrait
		elif base_textures.has(active_sprite):
			active_sprite.texture = base_textures[active_sprite]

		var atlas := active_sprite.texture as AtlasTexture
		if atlas != null and atlas.atlas != null:
			var sheet_size := atlas.atlas.get_size()
			if sheet_size.x >= sprite_size * 2 or sheet_size.y >= sprite_size * 2:
				atlas.region = Rect2(line.portrait_coords.x * sprite_size, line.portrait_coords.y * sprite_size, sprite_size, sprite_size)
			else:
				atlas.region = Rect2(Vector2.ZERO, sheet_size)

		# Custom slot positioning if specified
		if line.slot != DialogLine.Slot.DEFAULT:
			if line.slot == DialogLine.Slot.HIDDEN:
				active_sprite.visible = false
			else:
				active_sprite.visible = true
				active_sprite.position = _get_slot_position(line.slot, speaker, has_saki)

	# Display text & speaker name
	var display_name: String = ""
	if speaker == character.NONE:
		display_name = line.speaker_name_override
	else:
		if not line.speaker_name_override.is_empty():
			display_name = line.speaker_name_override
		elif speaker >= 0 and speaker < character_names.size():
			display_name = character_names[speaker]

	if display_name.is_empty():
		dialog_text.text = line.text
	else:
		dialog_text.text = "[b][color=%s]%s[/color][/b]\n%s" % [name_color, display_name, line.text]

	# Execute FX
	_execute_effect(line, active_sprite)

	# SFX Audio
	if line.sfx != null and sfx_player != null:
		sfx_player.stream = line.sfx
		sfx_player.play()

	# Music cue
	if not line.music_cue.is_empty():
		music_cue_requested.emit(line.music_cue)


func _execute_effect(line: DialogLine, active_sprite: TextureRect) -> void:
	var effect := line.effect.to_lower().strip_edges()
	if effect.is_empty():
		return

	if effect == "shake" or effect == "shake_speaker":
		_shake_sprite(active_sprite)
	elif effect == "shake_left":
		_shake_sprite(player_sprite)
	elif effect == "shake_right":
		_shake_sprite(saki_sprite)
	elif effect == "slide_out":
		_slide_out_sprite(active_sprite)
	elif effect == "wobble" or effect == "rise":
		_wobble_rise_sprite(active_sprite)
	elif effect == "darken" and active_sprite != null:
		active_sprite.self_modulate = Color(0.25, 0.25, 0.25, 1.0)
	elif effect == "hide" and active_sprite != null:
		active_sprite.visible = false


func _shake_sprite(sprite: TextureRect) -> void:
	if sprite == null or not sprite.visible:
		return
	var base_pos := sprite.position
	var tween := create_tween()
	for i in range(4):
		var offset := Vector2(randf_range(-14.0, 14.0), randf_range(-6.0, 6.0))
		tween.tween_property(sprite, "position", base_pos + offset, 0.04)
	tween.tween_property(sprite, "position", base_pos, 0.04)


func _slide_out_sprite(sprite: TextureRect) -> void:
	if sprite == null or not sprite.visible:
		return
	var view_width := get_viewport().get_visible_rect().size.x
	var target_x: float = -sprite.size.x if sprite.position.x < view_width / 2.0 else view_width + 50.0
	var tween := create_tween()
	tween.tween_property(sprite, "position:x", target_x, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	sprite.visible = false


func _wobble_rise_sprite(sprite: TextureRect) -> void:
	if sprite == null or not sprite.visible:
		return
	var base_y := sprite.position.y
	sprite.position.y += 40.0
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", base_y, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _continue_dialog() -> void:
	if current_dialog_pos + 1 < active_lines.size():
		current_dialog_pos += 1
		_update_dialog(current_dialog_pos)
	else:
		_close_dialog()


func _close_dialog() -> void:
	dialog_opened = false

	if dialog_animation.has_animation("DialogCloseAnim"):
		dialog_animation.play("DialogCloseAnim")
		await dialog_animation.animation_finished

	dim_rect.visible = false
	$sprite_dialog.visible = false

	for sprite in sprites:
		sprite.visible = false
		if base_textures.has(sprite):
			sprite.texture = base_textures[sprite]

	dialog_finished.emit()


func _get_dialog_resource(situation_idx: int) -> DialogStruct:
	if dialog_files.has(situation_idx):
		var path: String = dialog_files[situation_idx]
		if ResourceLoader.exists(path):
			return load(path) as DialogStruct

	return null


func _input(event: InputEvent) -> void:
	if not dialog_opened:
		return

	if event.is_action_pressed("update_dialog") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_continue_dialog()
