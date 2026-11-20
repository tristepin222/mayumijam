
extends CharacterBody2D

signal physical_attack_started

@export_group("Movement")
@export var move_speed: float = 250.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0

@export_group("References")
@export var stats: CharacterStats
@export var ability_manager: Node

var facing_direction: float = 1.0

var dash_ability: PlayerAbility
var sword_ability: PlayerAbility
var danmaku_ability: PlayerAbility

func _ready() -> void:
	if stats == null:
		stats = $Stats

	if ability_manager == null:
		ability_manager = get_node("../AbilityManager")

	dash_ability = $Abilities/Dash as PlayerAbility
	sword_ability = $Abilities/SwordAttack as PlayerAbility
	danmaku_ability = $Abilities/DanmakuShot as PlayerAbility
	
	# Give every ability its references.
	for ability in $Abilities.get_children():
		if ability is PlayerAbility:
			ability.setup(self, ability_manager)


func _physics_process(delta: float) -> void:
	# Dash controls Mayumi's movement while active.
	if dash_ability != null and dash_ability.is_dashing:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal movement.
	var direction := 0.0

	if Input.is_action_pressed("move_right"):
		direction += 1.0

	if Input.is_action_pressed("move_left"):
		direction -= 1.0

	velocity.x = direction * move_speed

	# Update facing direction.
	if direction != 0.0:
		facing_direction = signf(direction)

	# Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		if sword_ability != null:
			sword_ability.activate()

	if event.is_action_pressed("dash"):
		if dash_ability != null:
			dash_ability.activate()
			
	if event.is_action_pressed("danmaku_shot"):
		if danmaku_ability != null:
			danmaku_ability.activate()
