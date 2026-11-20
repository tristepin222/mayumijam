
class_name SakiController
extends CharacterBody2D

@export_group("Movement")
@export var move_speed: float = 150.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0

@export_group("References")
@export var stats: CharacterStats

var move_direction: float = 0.0
var defeated := false


func _ready() -> void:
	if stats == null:
		stats = $Stats

	stats.died.connect(_on_defeated)


func _physics_process(delta: float) -> void:
	if defeated:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal movement controlled by BossAI
	velocity.x = move_direction * move_speed

	move_and_slide()


func set_move_direction(direction: float) -> void:
	move_direction = clampf(direction, -1.0, 1.0)


func jump() -> void:
	if is_on_floor() and not defeated:
		velocity.y = jump_velocity


func _on_defeated() -> void:
	defeated = true
	move_direction = 0.0
	velocity = Vector2.ZERO

	hide()
	set_physics_process(false)

	$CollisionShape2D.set_deferred("disabled", true)
