
extends CharacterBody2D

@export_group("Movement")
@export var move_speed: float = 250.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0

@export_group("Combat")
@export var attack_damage: int = 10
@export var attack_cooldown: float = 0.4

@export_group("References")
@export var stats: CharacterStats
@export var attack_area: Area2D

var can_attack := true


func _ready() -> void:
	if stats == null:
		stats = $Stats

	if attack_area == null:
		attack_area = $AttackArea


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()


func attack() -> void:
	if not can_attack:
		return

	can_attack = false

	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemies"):
			body.stats.take_damage(attack_damage)

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
