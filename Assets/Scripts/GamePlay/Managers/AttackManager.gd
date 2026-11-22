
extends Node

signal attack_started(attack_id: String)
signal attack_finished(attack_id: String)

@export var saki: SakiController
@export var player: CharacterBody2D

var attacks: Dictionary = {}
var is_executing := false


func _ready() -> void:
	if saki == null:
		saki = get_parent() as SakiController

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	# Register attack nodes
	for attack in get_children():
		if attack is BossAttack:
			attack.saki = saki
			attack.player = player
			attacks[attack.name.to_snake_case()] = attack


func execute_attack(attack_id: String) -> void:
	if is_executing:
		return

	if not attacks.has(attack_id):
		push_warning("Unknown boss attack: " + attack_id)
		return

	is_executing = true

	var attack: BossAttack = attacks[attack_id]

	attack_started.emit(attack_id)
	print("Executing attack: ", attack_id)

	await attack.execute()

	attack_finished.emit(attack_id)
	is_executing = false
