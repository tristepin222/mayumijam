class_name UpgradeStruct
extends RefCounted

enum Type { HEALTH, DAMAGE, ABILITY, STORY }

var type: Type
var upgrade_name: String
var value: float
var ability_index: int


func _init(p_type: Type = Type.HEALTH, p_upgrade_name: String = "name", p_value: float = 1.0, p_ability_index: int = 0) -> void:
	type = p_type
	upgrade_name = p_upgrade_name
	value = p_value
	ability_index = p_ability_index
