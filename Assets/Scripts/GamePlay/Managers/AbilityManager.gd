
extends Node

signal ability_unlocked(ability_id: String)
signal ability_used(ability_id: String)

# For testing purposes
func _ready() -> void:
	unlock_ability("dash")
	equip_ability("dash")
	unlock_ability("sword_attack")
	equip_ability("sword_attack")
	unlock_ability("danmaku_shot")
	equip_ability("danmaku_shot")
	unlock_ability("haniwa_leap")
	equip_ability("haniwa_leap")
	unlock_ability("shattering_blow")
	equip_ability("shattering_blow")
	unlock_ability("haniwa_wall")
	equip_ability("haniwa_wall")
	unlock_ability("clay_graze")
	equip_ability("clay_graze")
	unlock_ability("haniwa_charge")
	equip_ability("haniwa_charge")
	unlock_ability("ceramic_barrage")
	equip_ability("ceramic_barrage")
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
