
class_name AbilityManager
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



const ABILITY_STRING_TO_INT: Dictionary = {
	"dash": AbilityIDs.Ability.DASH,
	"attack": AbilityIDs.Ability.ATTACK,
	"sword_attack": AbilityIDs.Ability.ATTACK,
	"danmaku": AbilityIDs.Ability.DANMAKU,
	"danmaku_shot": AbilityIDs.Ability.DANMAKU,
	"clay_graze": AbilityIDs.Ability.CLAY_GRAZE,
	"haniwa_leap": AbilityIDs.Ability.HANIWA_LEAP,
	"arrow_volley": AbilityIDs.Ability.ARROW_VOLLEY,
	"shattering_blow": AbilityIDs.Ability.SHATTERING_BLOW,
	"haniwa_charge": AbilityIDs.Ability.HANIWA_CHARGE,
	"ceramic_barrage": AbilityIDs.Ability.CERAMIC_BARRAGE,
	"haniwa_wall": AbilityIDs.Ability.HANIWA_WALL,
	"ceramic_skin": AbilityIDs.Ability.CERAMIC_SKIN,
	"haniwa_armor": AbilityIDs.Ability.HANIWA_ARMOR,
}

func _resolve_ability_id(ability: Variant) -> int:
	if ability is int:
		return ability
	elif ability is String:
		var key: String = ability.to_lower().strip_edges()
		if ABILITY_STRING_TO_INT.has(key):
			return ABILITY_STRING_TO_INT[key]
	return -1


func unlock_ability(ability: Variant) -> void:
	var ability_id: int = _resolve_ability_id(ability)
	if ability_id < 0 or unlocked_abilities.has(ability_id):
		return

	unlocked_abilities.append(ability_id)
	ability_unlocked.emit(ability_id)


func equip_ability(ability: Variant) -> void:
	var ability_id: int = _resolve_ability_id(ability)
	if ability_id < 0 or not unlocked_abilities.has(ability_id):
		return

	if equipped_abilities.has(ability_id):
		return

	equipped_abilities.append(ability_id)


func unequip_ability(ability: Variant) -> void:
	var ability_id: int = _resolve_ability_id(ability)
	if ability_id >= 0:
		equipped_abilities.erase(ability_id)


func has_ability(ability: Variant) -> bool:
	var ability_id: int = _resolve_ability_id(ability)
	return ability_id >= 0 and unlocked_abilities.has(ability_id)


func can_use_ability(ability: Variant) -> bool:
	var ability_id: int = _resolve_ability_id(ability)
	return ability_id >= 0 and equipped_abilities.has(ability_id)


func use_ability(ability: Variant) -> void:
	var ability_id: int = _resolve_ability_id(ability)
	if ability_id < 0 or not can_use_ability(ability_id):
		return

	ability_used.emit(ability_id)
