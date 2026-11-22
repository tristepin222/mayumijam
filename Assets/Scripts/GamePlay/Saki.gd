
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

var is_jumping := false
var is_cracked := false
var is_staggered := false
var stagger_timer := 0.0

func _ready() -> void:
	if stats == null:
		stats = $Stats

	stats.died.connect(_on_defeated)


func _physics_process(delta: float) -> void:
	if defeated:
		return

	if is_staggered:
		stagger_timer -= delta
		move_direction = 0.0
		velocity.x = 0.0

		if stagger_timer <= 0.0:
			is_staggered = false

	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal movement controlled by BossAI.
	if is_staggered:
		velocity.x = 0.0
	else:
		velocity.x = move_direction * move_speed

	move_and_slide()


func set_move_direction(direction: float) -> void:
	move_direction = clampf(direction, -1.0, 1.0)


func jump() -> void:
	if is_on_floor() and not defeated:
		is_jumping = true
		await get_tree().create_timer(1.0).timeout
		velocity.y = jump_velocity
		is_jumping = false


func _on_defeated() -> void:
	defeated = true
	move_direction = 0.0
	velocity = Vector2.ZERO

	hide()
	set_physics_process(false)

	$CollisionShape2D.set_deferred("disabled", true)
	
func crack() -> void:
	is_cracked = true
	print("Saki is cracked!")
	
func break_crack(stagger_duration: float) -> void:
	is_cracked = false
	is_staggered = true
	stagger_timer = stagger_duration

	move_direction = 0.0
	velocity.x = 0.0

	print("Shattering Blow! Saki is staggered.")
