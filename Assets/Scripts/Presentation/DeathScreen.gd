extends CanvasLayer

@export var title_text: String = "YOU DIED"
@export var button_text: String = "Continue"
@export var title_color: Color = Color(0.75, 0.1, 0.1)
@export var fade_time: float = 0.6

var root: Control
var retry_button: Button


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.75)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	center.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", title_color)
	box.add_child(title)

	retry_button = Button.new()
	retry_button.text = button_text
	retry_button.custom_minimum_size = Vector2(240.0, 56.0)
	retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_button.add_theme_font_size_override("font_size", 28)
	retry_button.pressed.connect(_on_retry_pressed)
	box.add_child(retry_button)

	root.hide()


func show_screen() -> void:
	get_tree().paused = true

	root.modulate.a = 0.0
	root.show()

	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, fade_time)

	retry_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if root != null and root.visible and event.is_action_pressed("attack"):
		get_viewport().set_input_as_handled()
		_on_retry_pressed()


func _on_retry_pressed() -> void:
	get_tree().paused = false

	var game_manager = get_node_or_null("/root/GameManager")

	if game_manager != null:
		game_manager.continue_after_death()
		return

	get_tree().reload_current_scene()
