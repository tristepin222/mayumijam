
extends Node

signal ability_unlocked(ability_id: int)
signal ability_used(ability_id: int)

# Abilities Mayumi has unlocked.
var unlocked_abilities: Array[int] = []

# Abilities currently available for use.
var equipped_abilities: Array[int] = []


# Temporary testing
func _ready() -> void:
	# Basic actions
	for ability_id in [
		AbilityIDs.Ability.DASH,
		AbilityIDs.Ability.ATTACK,
		AbilityIDs.Ability.DANMAKU
	]:
		unlock_ability(ability_id)
		equip_ability(ability_id)

	# Temporary: unlock all upgrades for testing.
	for ability_id in [
		AbilityIDs.Ability.CLAY_GRAZE,
		AbilityIDs.Ability.HANIWA_LEAP,
		AbilityIDs.Ability.ARROW_VOLLEY,
		AbilityIDs.Ability.SHATTERING_BLOW,
		AbilityIDs.Ability.HANIWA_CHARGE,
		AbilityIDs.Ability.CERAMIC_BARRAGE,
		AbilityIDs.Ability.HANIWA_WALL,
		AbilityIDs.Ability.CERAMIC_SKIN,
		AbilityIDs.Ability.HANIWA_ARMOR
	]:
		unlock_ability(ability_id)
		equip_ability(ability_id)


func unlock_ability(ability_id: int) -> void:
	if unlocked_abilities.has(ability_id):
		return

	unlocked_abilities.append(ability_id)
	ability_unlocked.emit(ability_id)


func equip_ability(ability_id: int) -> void:
	if not unlocked_abilities.has(ability_id):
		return

	if equipped_abilities.has(ability_id):
		return

	equipped_abilities.append(ability_id)


func unequip_ability(ability_id: int) -> void:
	equipped_abilities.erase(ability_id)


func has_ability(ability_id: int) -> bool:
	return unlocked_abilities.has(ability_id)


func can_use_ability(ability_id: int) -> bool:
	return equipped_abilities.has(ability_id)


func use_ability(ability_id: int) -> void:
	if not can_use_ability(ability_id):
		return

	ability_used.emit(ability_id)
