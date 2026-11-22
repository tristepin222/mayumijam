extends Node

signal choice_made(index: int)

@export var dialog_player: DialogPlayer
@export var garden_texture: Texture2D
@export var upgrade_texture: Texture2D
@export var background_color: Color = Color(0.16, 0.07, 0.04)
@export var card_size: Vector2 = Vector2(260.0, 190.0)
@export var dialog_dim_alpha: float = 0.15
@export var card_color: Color = Color(0.13, 0.05, 0.03, 0.92)
@export var card_border_color: Color = Color(1.0, 0.72, 0.4, 0.45)
@export var card_focus_color: Color = Color(1.0, 0.88, 0.55, 1.0)
@export var shopkeeper_height_ratio: float = 0.82
@export var shopkeeper_card_shift: float = 260.0

var game_manager
var ui_layer: CanvasLayer
var panel: Control
var background: TextureRect
var shopkeeper: TextureRect
var panel_right_margin := 0.0


func _ready() -> void:
	game_manager = get_node_or_null("/root/GameManager")

	_build_background()

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)

	if game_manager == null:
		push_warning("Kiln: GameManager autoload is missing.")
		return

	await get_tree().process_frame

	if dialog_player != null and dialog_player.dim_rect != null:
		dialog_player.dim_rect.color.a = dialog_dim_alpha

	if game_manager.kiln_mode == "win":
		game_manager.play_music("final_cutscene")
	else:
		game_manager.play_music(game_manager.get_shop_track(), game_manager.SHOP_MUSIC_START)

	match game_manager.kiln_mode:
		"win":
			_run_ending(-1, "Saki has been defeated!")
		"lose":
			_run_ending(DialogManager.situations.A3_D, "Mayumi has become a full Haniwa.", {"mayumi_damaged": true, "keiki_outfit": "goddess"})
		_:
			_run_upgrade()


func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)

	var rect := ColorRect.new()
	rect.color = background_color
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)

	background = TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.texture = garden_texture
	layer.add_child(background)


func _set_background(texture: Texture2D) -> void:
	if background != null and texture != null:
		background.texture = texture


func _run_upgrade() -> void:
	if dialog_player != null and game_manager != null:
		var pre_dialog: int = game_manager.get_workshop_pre_dialog()
		if pre_dialog >= 0:
			await dialog_player.play_dialog(pre_dialog, {"mayumi_damaged": true})

	var offer: Array[UpgradeStruct] = game_manager.get_upgrade_offer()

	if offer.is_empty():
		await _show_message("Keiki has nothing left to give you.", "Back to the fight")
		game_manager.start_fight()
		return

	var titles: Array[String] = []
	var descriptions: Array[String] = []

	for upgrade in offer:
		titles.append(upgrade.upgrade_name)
		descriptions.append(game_manager.describe_upgrade(upgrade))

	_set_background(upgrade_texture)
	_show_shopkeeper()

	var index := await _show_choices("Choose Keiki's gift", titles, descriptions)

	_hide_shopkeeper()
	game_manager._select_upgrade(offer[index])

	if dialog_player != null and game_manager != null:
		var post_dialog: int = game_manager.get_workshop_post_dialog()
		if post_dialog >= 0:
			await dialog_player.play_dialog(post_dialog, {})

	var story: Dictionary = game_manager.last_story_upgrade

	if not story.is_empty():
		await _show_message(
			"Keiki reshapes you further...\n\nStory upgrade: %s\n%s" % [story["name"], story["description"]],
			"Continue"
		)

	game_manager.start_fight()


func _run_ending(situation: int, title: String, context: Dictionary = {}) -> void:
	if dialog_player != null and situation >= 0:
		await dialog_player.play_dialog(situation, context)

	await _show_message(
		"THE END\n\n%s\nDeaths: %d" % [title, game_manager.deaths],
		"Main Menu"
	)

	game_manager.go_to_menu()


func _show_choices(title: String, titles: Array[String], descriptions: Array[String]) -> int:
	_open_panel()

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	panel.add_child(box)

	box.add_child(_make_label(title, 36))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)

	var buttons: Array[Button] = []

	for i in range(titles.size()):
		var button := Button.new()
		button.text = "%s\n\n%s" % [titles[i], descriptions[i]]
		button.custom_minimum_size = card_size
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 18)
		_style_button(button)
		button.pressed.connect(func(): choice_made.emit(i))
		row.add_child(button)
		buttons.append(button)

	buttons[0].grab_focus()

	var index: int = await choice_made
	_close_panel()

	return index


func _show_message(text: String, button_text: String) -> void:
	_open_panel()

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	panel.add_child(box)

	box.add_child(_make_label(text, 28))

	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(240.0, 56.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 24)
	_style_button(button)
	button.pressed.connect(func(): choice_made.emit(0))
	box.add_child(button)

	button.grab_focus()

	await choice_made
	_close_panel()


func _style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = card_color
	normal.border_color = card_border_color
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.set_content_margin_all(14)

	var focused := normal.duplicate() as StyleBoxFlat
	focused.border_color = card_focus_color
	focused.set_border_width_all(4)
	focused.bg_color = card_color.lightened(0.12)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", focused)
	button.add_theme_stylebox_override("focus", focused)
	button.add_theme_stylebox_override("pressed", focused)
	button.add_theme_color_override("font_color", Color(1.0, 0.93, 0.85))
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


func _open_panel() -> void:
	_close_panel()

	panel = CenterContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_right = -panel_right_margin
	ui_layer.add_child(panel)


func _show_shopkeeper() -> void:
	var texture := PortraitLibrary.get_portrait(DialogManager.characters.KEIKI, "shop", {}, false)

	if texture == null:
		return

	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)

	var view_size := get_viewport().get_visible_rect().size
	var height := view_size.y * shopkeeper_height_ratio

	shopkeeper = TextureRect.new()
	shopkeeper.texture = texture
	shopkeeper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shopkeeper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shopkeeper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shopkeeper.size = Vector2(height, height)
	shopkeeper.position = Vector2(view_size.x, view_size.y - height)
	shopkeeper.modulate.a = 0.0
	layer.add_child(shopkeeper)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(shopkeeper, "position:x", view_size.x - height, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(shopkeeper, "modulate:a", 1.0, 0.25)

	panel_right_margin = shopkeeper_card_shift


func _hide_shopkeeper() -> void:
	panel_right_margin = 0.0

	if is_instance_valid(shopkeeper):
		shopkeeper.get_parent().queue_free()

	shopkeeper = null


func _close_panel() -> void:
	if is_instance_valid(panel):
		panel.queue_free()

	panel = null


func _unhandled_input(event: InputEvent) -> void:
	if panel == null or not event.is_action_pressed("sword"):
		return

	var focused := get_viewport().gui_get_focus_owner() as Button

	if focused != null:
		get_viewport().set_input_as_handled()
		focused.pressed.emit()
