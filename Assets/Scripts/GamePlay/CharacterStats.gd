
class_name CharacterStats
extends Node

signal died
signal health_changed(current_health: int, max_health: int)

enum DamagePhase {
	PHASE_1,
	PHASE_2
}

@export var max_health: int = 100
@export var armor: int = 0

var health: int
var immune_to_phase_one := false


func _ready() -> void:
	health = max_health


func take_damage(
		amount: int,
		phase: DamagePhase = DamagePhase.PHASE_1
) -> void:
	if health <= 0:
		return

	if immune_to_phase_one and phase == DamagePhase.PHASE_1:
		return

	health = max(health - amount, 0)
	health_changed.emit(health, max_health)

	if health == 0:
		died.emit()


func reset() -> void:
	health = max_health
	health_changed.emit(health, max_health)
