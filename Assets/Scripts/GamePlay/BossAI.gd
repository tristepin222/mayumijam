
extends Node

signal phase_changed(phase: int)
signal attack_selected(attack_id: String)


enum BossPhase {
	PHASE_1,
	PHASE_2
}

enum BossState {
	IDLE,
	CHASE,
	ATTACKING
}


const PHASE_1_ATTACKS = [
	"dive",
	"normal_danmaku",
	"comeback_danmaku",
	"tectonic_push"
]

const PHASE_2_ATTACKS = [
	"charge",
	"unleash"
]


@export_group("Phase Settings")
@export_range(0.0, 1.0) var phase_2_health_threshold: float = 0.5

@export_group("Combat")
@export var attack_range: float = 60.0
@export var attack_height_tolerance: float = 40.0
@export var attack_duration: float = 1.0
@export var attack_cooldown: float = 1.5

@export_group("References")
@export var player: CharacterBody2D
@export var attack_manager: Node


var saki: SakiController
var stats: CharacterStats

var current_phase: BossPhase = BossPhase.PHASE_1
var current_state: BossState = BossState.IDLE

var is_attacking := false
var attack_ready := true

var last_attack_id: String = ""


func _ready() -> void:
	saki = get_parent() as SakiController
	stats = saki.get_node("Stats") as CharacterStats

	if player == null:
		player = get_tree().get_first_node_in_group("player")
		
	if attack_manager == null:
		attack_manager = get_node("../AttackManager")


func _physics_process(_delta: float) -> void:
	if saki == null or saki.defeated:
		return
		
	if saki.is_staggered:
		saki.set_move_direction(0.0)
		return

	_update_phase()

	if is_attacking:
		saki.set_move_direction(0.0)
		return

	if player == null:
		saki.set_move_direction(0.0)
		current_state = BossState.IDLE
		return

	var distance_x: float = player.global_position.x - saki.global_position.x
	var distance_y: float = saki.global_position.y - player.global_position.y

	# Check whether Mayumi is within attack range
	if absf(distance_x) <= attack_range and absf(distance_y) <= attack_height_tolerance:
		saki.set_move_direction(0.0)

		if attack_ready:
			_start_attack()

		return

	# Chase Mayumi
	current_state = BossState.CHASE
	saki.set_move_direction(signf(distance_x))

	# Jump if Mayumi is above Saki
	if distance_y > 60.0 and saki.is_on_floor():
		saki.jump()


func _update_phase() -> void:
	if current_phase == BossPhase.PHASE_1:
		if stats.health <= stats.max_health * phase_2_health_threshold:
			current_phase = BossPhase.PHASE_2

			print("Saki entered Phase 2!")
			phase_changed.emit(current_phase)


func _start_attack() -> void:
	if is_attacking or not attack_ready:
		return

	is_attacking = true
	attack_ready = false
	current_state = BossState.ATTACKING

	saki.set_move_direction(0.0)

	var attack_id := _choose_attack()

	print("Saki selected: ", attack_id)

	await attack_manager.execute_attack(attack_id)

	if saki.defeated:
		return

	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout

	if not saki.defeated:
		attack_ready = true


func _choose_attack() -> String:
	var available_attacks: Array

	if current_phase == BossPhase.PHASE_1:
		available_attacks = PHASE_1_ATTACKS.duplicate()
	else:
		available_attacks = PHASE_2_ATTACKS.duplicate()

	# Avoid choosing the same attack twice consecutively
	if available_attacks.size() > 1:
		available_attacks.erase(last_attack_id)

	var selected_attack: String = str(
		available_attacks[randi_range(0, available_attacks.size() - 1)]
	)

	last_attack_id = selected_attack

	return selected_attack
