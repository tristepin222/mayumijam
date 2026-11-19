
extends Node

signal ability_unlocked(ability_id: String)
signal ability_used(ability_id: String)

# Abilities Mayumi has unlocked
var unlocked_abilities: Array[String] = []

# Abilities currently available for use
var equipped_abilities: Array[String] = []


func unlock_ability(ability_id: String) -> void:
	if unlocked_abilities.has(ability_id):
		return

	unlocked_abilities.append(ability_id)
	ability_unlocked.emit(ability_id)


func equip_ability(ability_id: String) -> void:
	if not unlocked_abilities.has(ability_id):
		return

	if equipped_abilities.has(ability_id):
		return

	equipped_abilities.append(ability_id)


func has_ability(ability_id: String) -> bool:
	return unlocked_abilities.has(ability_id)


func can_use_ability(ability_id: String) -> bool:
	return equipped_abilities.has(ability_id)


func use_ability(ability_id: String) -> void:
	if not can_use_ability(ability_id):
		return

	ability_used.emit(ability_id)
