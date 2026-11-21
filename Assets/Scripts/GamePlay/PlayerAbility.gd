class_name PlayerAbility
extends Node

var mayumi: CharacterBody2D
var ability_manager: Node

var ability_id: int


func setup(
	player: CharacterBody2D,
	manager: Node
) -> void:
	mayumi = player
	ability_manager = manager


func can_activate() -> bool:
	if mayumi == null or ability_manager == null:
		return false

	return ability_manager.can_use_ability(ability_id)


func activate() -> void:
	pass


func cancel() -> void:
	pass
