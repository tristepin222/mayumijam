
class_name CharacterStats
extends Node

signal died
signal health_changed(current_health: int, max_health: int)
signal invincibility_changed(is_active: bool)

enum DamagePhase {
	PHASE_1,
	PHASE_2
}

@export var max_health: int = 100
@export var armor: int = 0

@export var invincibility_time: float = 0.0

var health: int
var is_invulnerable := false
var immune_to_phase_one := false


func _ready() -> void:
	health = max_health


func take_damage(
		amount: int,
		phase: DamagePhase = DamagePhase.PHASE_1
) -> void:
	if health <= 0:
		return

	if is_invulnerable:
		return

	if immune_to_phase_one and phase == DamagePhase.PHASE_1:
		return

	var owner_node := get_parent()

	if owner_node != null and "is_invincible" in owner_node and owner_node.get("is_invincible"):
		return

	health = max(health - amount, 0)
	health_changed.emit(health, max_health)

	if health == 0:
		died.emit()
		return

	if invincibility_time > 0.0:
		_start_invincibility()


func _start_invincibility() -> void:
	is_invulnerable = true
	invincibility_changed.emit(true)

	await get_tree().create_timer(invincibility_time, false).timeout

	is_invulnerable = false
	invincibility_changed.emit(false)


func reset() -> void:
	health = max_health
	health_changed.emit(health, max_health)
