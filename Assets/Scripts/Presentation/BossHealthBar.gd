extends CanvasLayer

@export var boss_stats: CharacterStats
@export var boss_name: String = "Saki Kurokoma"

@export_group("Layout")
@export var bar_size: Vector2 = Vector2(360.0, 18.0)
@export var margin: Vector2 = Vector2(16.0, 16.0)
@export var name_font_size: int = 20

@export_group("Colors")
@export var fill_color: Color = Color(0.75, 0.12, 0.12)
@export var trail_color: Color = Color(0.95, 0.8, 0.3)
@export var back_color: Color = Color(0.0, 0.0, 0.0, 0.6)
@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.8)

@export_group("Behaviour")
@export_range(0.0, 1.0) var phase_marker_ratio: float = 0.5
@export var trail_delay: float = 0.4
@export var trail_speed: float = 0.5

var bar: Control
var shown_ratio := 1.0
var trail_ratio := 1.0
var trail_wait := 0.0


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	box.offset_left = -(bar_size.x + margin.x)
	box.offset_right = -margin.x
	box.offset_top = margin.y
	box.offset_bottom = margin.y
	box.add_theme_constant_override("separation", 4)
	root.add_child(box)

	var label := Label.new()
	label.text = boss_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", name_font_size)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	box.add_child(label)

	bar = Control.new()
	bar.custom_minimum_size = bar_size
	bar.draw.connect(_draw_bar)
	box.add_child(bar)

	if boss_stats == null:
		push_warning("BossHealthBar: Assign Saki's Stats node.")
		return

	boss_stats.health_changed.connect(_on_health_changed)


func _on_health_changed(current_health: int, max_health: int) -> void:
	var new_ratio := clampf(float(current_health) / float(maxi(max_health, 1)), 0.0, 1.0)

	if new_ratio < shown_ratio:
		trail_wait = trail_delay
	else:
		trail_ratio = new_ratio

	shown_ratio = new_ratio
	bar.queue_redraw()


func _process(delta: float) -> void:
	if trail_ratio <= shown_ratio:
		return

	if trail_wait > 0.0:
		trail_wait -= delta
		return

	trail_ratio = maxf(shown_ratio, trail_ratio - trail_speed * delta)
	bar.queue_redraw()


func _draw_bar() -> void:
	var full := Rect2(Vector2.ZERO, bar_size)

	bar.draw_rect(full, back_color)
	bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar_size.x * trail_ratio, bar_size.y)), trail_color)
	bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar_size.x * shown_ratio, bar_size.y)), fill_color)

	if phase_marker_ratio > 0.0 and phase_marker_ratio < 1.0:
		var x := bar_size.x * phase_marker_ratio
		bar.draw_line(Vector2(x, 0.0), Vector2(x, bar_size.y), border_color, 2.0)

	bar.draw_rect(full, border_color, false, 2.0)
