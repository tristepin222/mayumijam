extends Node2D

@export var color: Color = Color(1.0, 1.0, 1.0, 0.4)

var area: Area2D


func _ready() -> void:
	area = get_parent() as Area2D
	visible = false

	if area == null:
		push_warning("HitboxIndicator: Parent must be an Area2D.")
		set_process(false)


func _process(_delta: float) -> void:
	var active := area.monitoring

	if active != visible:
		visible = active
		queue_redraw()


func _draw() -> void:
	if area == null:
		return

	for child in area.get_children():
		var collision := child as CollisionShape2D

		if collision == null or collision.shape == null or collision.disabled:
			continue

		draw_set_transform(collision.position, collision.rotation, collision.scale)

		var rect := collision.shape as RectangleShape2D
		var circle := collision.shape as CircleShape2D

		if rect != null:
			draw_rect(Rect2(-rect.size / 2.0, rect.size), color)
		elif circle != null:
			draw_circle(Vector2.ZERO, circle.radius, color)

	draw_set_transform(Vector2.ZERO)
