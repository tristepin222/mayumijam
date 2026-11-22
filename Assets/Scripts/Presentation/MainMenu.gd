extends Node

@export var background_texture: Texture2D
@export var game_title: String = "Entrusting This World to Ceramics"
@export var show_title_text: bool = false
@export var main_shade: float = 0.0
@export var screen_shade: float = 0.78
@export var main_menu_margin: Vector2 = Vector2(0.07, 0.06)
@export var button_size: Vector2 = Vector2(300.0, 66.0)
@export var button_texture: Texture2D = preload("res://Assets/Textures/Menu/button_smoke.png")
@export var button_focus_texture: Texture2D = preload("res://Assets/Textures/Menu/button_fire.png")
@export var button_focus_scale: float = 1.06
@export var button_color: Color = Color(0.13, 0.05, 0.03, 0.92)
@export var button_border_color: Color = Color(1.0, 0.72, 0.4, 0.45)
@export var button_focus_color: Color = Color(1.0, 0.88, 0.55, 1.0)
@export_multiline var credits_text: String = """RoyalBlue: Designer / Programmer
diegobnready: Artist
Oyster: Artist
Joel: Artist
AngryCow: Writer
Tristepin: Programmer
Gelis: Programmer"""
@export_multiline var credits_footer: String = """A Touhou Project fan game. Mayumi Joutouguu, Saki Kurokoma and Keiki Haniyasushin
are characters from Touhou Project © Team Shanghai Alice / ZUN."""

const CONTROL_ACTIONS = [
	["Move", ["move_left", "move_right"]],
	["Jump / Haniwa Leap", ["jump"]],
	["Attack", ["sword"]],
	["Dash", ["dash"]],
	["Danmaku", ["danmaku_shot"]],
	["Haniwa Wall", ["haniwa_wall"]],
	["Haniwa Charge", ["haniwa_charge"]],
	["Ceramic Barrage", ["ceramic_barrage"]],
]

var ui_layer: CanvasLayer
var shade: ColorRect
var panel: Control


func _ready() -> void:
	get_tree().paused = false

	var music := get_node_or_null("/root/MusicManager")

	if music != null:
		music.play("main_menu")

	var background_layer := CanvasLayer.new()
	background_layer.layer = -1
	add_child(background_layer)

	var fill := ColorRect.new()
	fill.color = Color(0.16, 0.07, 0.04)
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_layer.add_child(fill)

	if background_texture != null:
		var background := TextureRect.new()
		background.texture = background_texture
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background_layer.add_child(background)

	shade = ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, main_shade)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_layer.add_child(shade)

	ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	_show_main()


func _show_main() -> void:
	var box := _open_corner_panel(2)
	_set_shade(main_shade)

	if show_title_text:
		box.add_child(_make_label(game_title, 52))

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0.0, 24.0)
		box.add_child(spacer)

	var start := _make_button("Start")
	start.pressed.connect(_on_start_pressed)
	box.add_child(start)

	var options := _make_button("Options")
	options.pressed.connect(_show_options)
	box.add_child(options)

	var controls := _make_button("Controls")
	controls.pressed.connect(_show_controls)
	box.add_child(controls)

	var credits := _make_button("Credits")
	credits.pressed.connect(_show_credits)
	box.add_child(credits)

	if not OS.has_feature("web"):
		var quit := _make_button("Quit")
		quit.pressed.connect(func(): get_tree().quit())
		box.add_child(quit)

	start.grab_focus()


func _show_options() -> void:
	var box := _open_panel(14)

	box.add_child(_make_label("Options", 44))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 18)
	box.add_child(grid)

	var master_slider := _add_volume_row(grid, "Master Volume", GameSettings.master_volume)
	master_slider.value_changed.connect(func(value: float):
		GameSettings.master_volume = value / 100.0
		GameSettings.apply(get_tree())
	)

	var music_slider := _add_volume_row(grid, "Music Volume", GameSettings.music_volume)
	music_slider.value_changed.connect(func(value: float):
		GameSettings.music_volume = value / 100.0
		GameSettings.apply(get_tree())
	)

	var sfx_slider := _add_volume_row(grid, "SFX Volume", GameSettings.sfx_volume)
	sfx_slider.value_changed.connect(func(value: float):
		GameSettings.sfx_volume = value / 100.0
		GameSettings.apply(get_tree())
		Sfx.play("menu_select")
	)

	var fullscreen_label := _make_label("Fullscreen", 26)
	fullscreen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(fullscreen_label)

	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.button_pressed = GameSettings.fullscreen
	fullscreen_toggle.focus_mode = Control.FOCUS_ALL
	fullscreen_toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	fullscreen_toggle.add_theme_stylebox_override("focus", _make_focus_box())
	grid.add_child(fullscreen_toggle)

	var fullscreen_state := _make_label("On" if GameSettings.fullscreen else "Off", 24)
	fullscreen_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	fullscreen_state.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	grid.add_child(fullscreen_state)

	fullscreen_toggle.toggled.connect(func(enabled: bool):
		fullscreen_state.text = "On" if enabled else "Off"
		GameSettings.fullscreen = enabled
		GameSettings.apply(get_tree())
	)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 16.0)
	box.add_child(spacer)

	var back := _make_button("Back")
	back.pressed.connect(func():
		GameSettings.save_settings()
		_show_main()
	)
	box.add_child(back)

	master_slider.grab_focus()


func _add_volume_row(grid: GridContainer, title: String, value: float) -> HSlider:
	var label := _make_label(title, 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	grid.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.value = round(value * 100.0)
	slider.custom_minimum_size = Vector2(260.0, 32.0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_slider(slider)
	grid.add_child(slider)

	var value_label := _make_label("%d%%" % int(slider.value), 24)
	value_label.custom_minimum_size = Vector2(70.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	grid.add_child(value_label)

	slider.value_changed.connect(func(new_value: float): value_label.text = "%d%%" % int(new_value))

	return slider


func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = button_color
	track.border_color = button_border_color
	track.set_border_width_all(2)
	track.set_corner_radius_all(6)
	track.content_margin_top = 6.0
	track.content_margin_bottom = 6.0

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.5, 0.22)
	fill.set_corner_radius_all(6)
	fill.content_margin_top = 6.0
	fill.content_margin_bottom = 6.0

	var fill_focus := fill.duplicate() as StyleBoxFlat
	fill_focus.bg_color = button_focus_color

	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_focus)
	slider.add_theme_stylebox_override("focus", _make_focus_box())


func _make_focus_box() -> StyleBoxFlat:
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = button_focus_color
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(8)
	focus.expand_margin_left = 6.0
	focus.expand_margin_right = 6.0
	focus.expand_margin_top = 4.0
	focus.expand_margin_bottom = 4.0
	return focus


func _show_credits() -> void:
	var box := _open_panel(12)

	box.add_child(_make_label("Credits", 44))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)

	for line in credits_text.strip_edges().split("\n", false):
		var parts := line.split(":", true, 1)
		var person := parts[0].strip_edges()
		var role := parts[1].strip_edges() if parts.size() > 1 else ""

		var name_label := _make_label(person, 28)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(name_label)

		var role_label := _make_label(role, 28)
		role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		role_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
		grid.add_child(role_label)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 10.0)
	box.add_child(gap)

	var footer := _make_label(credits_footer.strip_edges(), 16)
	footer.add_theme_color_override("font_color", Color(1.0, 0.93, 0.85, 0.8))
	footer.add_theme_constant_override("outline_size", 6)
	box.add_child(footer)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 10.0)
	box.add_child(spacer)

	var back := _make_button("Back")
	back.pressed.connect(_show_main)
	box.add_child(back)

	back.grab_focus()


func _show_controls() -> void:
	var box := _open_panel(10)

	box.add_child(_make_label("Controls", 44))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)

	for entry in CONTROL_ACTIONS:
		var keys: Array[String] = []

		for action in entry[1]:
			for key in _get_action_keys(action):
				if not keys.has(key):
					keys.append(key)

		var name_label := _make_label(entry[0], 24)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(name_label)

		var key_label := _make_label(" / ".join(keys), 24)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		key_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
		grid.add_child(key_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 16.0)
	box.add_child(spacer)

	var back := _make_button("Back")
	back.pressed.connect(_show_main)
	box.add_child(back)

	back.grab_focus()


func _get_action_keys(action: String) -> Array[String]:
	var keys: Array[String] = []

	if not InputMap.has_action(action):
		return keys

	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey

		if key_event == null:
			continue

		var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
		keys.append(OS.get_keycode_string(code))

	return keys


func _on_start_pressed() -> void:
	var game_manager = get_node_or_null("/root/GameManager")

	if game_manager != null:
		game_manager.start_new_run()
	else:
		get_tree().change_scene_to_file("res://Assets/Scenes/MainGame.tscn")


func _set_shade(alpha: float) -> void:
	if shade == null:
		return

	create_tween().tween_property(shade, "color:a", alpha, 0.25)


func _open_corner_panel(separation: int) -> VBoxContainer:
	if is_instance_valid(panel):
		panel.queue_free()

	var view_size := get_viewport().get_visible_rect().size

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(view_size.x * main_menu_margin.x))
	margin.add_theme_constant_override("margin_bottom", int(view_size.y * main_menu_margin.y))
	ui_layer.add_child(margin)
	panel = margin

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.size_flags_vertical = Control.SIZE_SHRINK_END
	box.add_theme_constant_override("separation", separation)
	margin.add_child(box)

	return box


func _open_panel(separation: int) -> VBoxContainer:
	_set_shade(screen_shade)

	if is_instance_valid(panel):
		panel.queue_free()

	panel = CenterContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", separation)
	panel.add_child(box)

	return box


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 8)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.04, 0.02))
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = button_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 26)

	var normal: StyleBox
	var focused: StyleBox

	if button_texture != null and button_focus_texture != null:
		var smoke := StyleBoxTexture.new()
		smoke.texture = button_texture
		var fire := StyleBoxTexture.new()
		fire.texture = button_focus_texture
		normal = smoke
		focused = fire
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = button_color
		flat.border_color = button_border_color
		flat.set_border_width_all(2)
		flat.set_corner_radius_all(10)
		var flat_focus := flat.duplicate() as StyleBoxFlat
		flat_focus.border_color = button_focus_color
		flat_focus.set_border_width_all(4)
		flat_focus.bg_color = button_color.lightened(0.12)
		normal = flat
		focused = flat_focus

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", focused)
	button.add_theme_stylebox_override("pressed", focused)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color(0.18, 0.06, 0.03))
	button.add_theme_constant_override("outline_size", 8)

	button.resized.connect(func(): button.pivot_offset = button.size * 0.5)
	button.focus_entered.connect(func():
		button.add_theme_stylebox_override("normal", focused)
		create_tween().tween_property(button, "scale", Vector2.ONE * button_focus_scale, 0.1)
	)
	button.focus_exited.connect(func():
		button.add_theme_stylebox_override("normal", normal)
		create_tween().tween_property(button, "scale", Vector2.ONE, 0.1)
	)

	var sound := "menu_back" if text == "Back" else "menu_select"
	button.pressed.connect(func(): Sfx.play(sound))

	return button


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("sword"):
		return

	var focused := get_viewport().gui_get_focus_owner() as BaseButton

	if focused == null:
		return

	get_viewport().set_input_as_handled()

	if focused.toggle_mode:
		focused.button_pressed = not focused.button_pressed
	else:
		focused.pressed.emit()
