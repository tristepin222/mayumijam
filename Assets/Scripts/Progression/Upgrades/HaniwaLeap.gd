
extends PlayerAbility

@export_group("Jump")
@export var jump_velocity: float = -400.0

var air_jump_used := false


func _ready() -> void:
	ability_id = AbilityIDs.Ability.HANIWA_LEAP


func _physics_process(_delta: float) -> void:
	if mayumi != null and mayumi.is_on_floor():
		air_jump_used = false


func activate() -> void:
	if not can_activate():
		return

	if mayumi.is_on_floor():
		return

	if air_jump_used:
		return

	ability_manager.use_ability(ability_id)

	air_jump_used = true
	mayumi.velocity.y = jump_velocity

	print("Mayumi used Haniwa Leap!")
