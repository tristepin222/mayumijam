class_name HeartHUD
extends CanvasLayer

@export var player_stats: CharacterStats
@export var full_heart: Texture2D
@export var empty_heart: Texture2D
@export var heart_size: Vector2 = Vector2(48.0, 48.0)
@export var margin: Vector2 = Vector2(16.0, 16.0)
@export var spacing: int = 6

var _hearts: Array[TextureRect] = []


func _ready() -> void:
	if player_stats == null:
		push_warning("HeartHUD: Assign Mayumi's Stats node.")
		return

	var row := HBoxContainer.new()
	row.position = margin
	row.add_theme_constant_override("separation", spacing)
	add_child(row)

	for i in range(player_stats.max_health):
		var heart := TextureRect.new()
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = heart_size
		row.add_child(heart)
		_hearts.append(heart)

	player_stats.health_changed.connect(_on_health_changed)
	_on_health_changed(player_stats.health, player_stats.max_health)


func _on_health_changed(current_health: int, _max_health: int) -> void:
	for i in range(_hearts.size()):
		_hearts[i].texture = full_heart if i < current_health else empty_heart
