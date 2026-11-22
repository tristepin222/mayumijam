
class_name BossAI
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
	"counter",
	"dive",
	"normal_danmaku",
	"comeback_danmaku",
	"tectonic_push"
]

const PHASE_2_ATTACKS = [
	"charge",
	"unleash",
	"danmaku_rain"
]

const FAR_ATTACKS = [
	"normal_danmaku",
	"comeback_danmaku",
	"tectonic_push",
	"charge"
]

const CLOSE_ATTACKS = [
	"dive",
	"counter",
	"danmaku_rain"
]

@export_group("Phase Settings")
@export_range(0.0, 1.0) var phase_2_health_threshold: float = 0.5

@export_group("Combat")
@export var attack_range: float = 60.0
@export var attack_height_tolerance: float = 40.0
@export var attack_duration: float = 1.0
@export var attack_cooldown: float = 1.5

@export_group("Positioning")
@export var arena_left_x: float = -120.0
@export var arena_right_x: float = 168.0
@export var arrive_tolerance: float = 6.0
@export var close_range: float = 90.0
@export var max_reposition_time: float = 3.0

@export_group("Telegraph")
@export var telegraph_time: float = 0.35
@export var telegraph_color: Color = Color(2.0, 2.0, 1.6)
@export var counter_ready_color: Color = Color(0.7, 0.8, 1.5)

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

var planned_attack: String = ""
var reposition_target_x := 0.0
var reposition_timer := 0.0

var sprite: CanvasItem


func _ready() -> void:
	saki = get_parent() as SakiController
	stats = saki.get_node("Stats") as CharacterStats

	if player == null:
		player = get_tree().get_first_node_in_group("player")
		
	if attack_manager == null:
		attack_manager = get_node("../AttackManager")

	sprite = saki.get_node_or_null("Sprite2D") as CanvasItem

	var counter := saki.get_node_or_null("AttackManager/Counter")

	if counter != null and counter.has_signal("counter_ready_changed"):
		counter.connect("counter_ready_changed", _on_counter_ready_changed)


func _on_counter_ready_changed(is_ready: bool) -> void:
	if sprite != null:
		sprite.self_modulate = counter_ready_color if is_ready else Color.WHITE


func _physics_process(delta: float) -> void:
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

	if not attack_ready:
		current_state = BossState.IDLE
		saki.set_move_direction(0.0)
		return

	if planned_attack == "":
		planned_attack = _choose_attack()
		reposition_timer = 0.0

		if planned_attack in FAR_ATTACKS:
			reposition_target_x = _get_far_corner_x()

	reposition_timer += delta

	if _is_in_position() or reposition_timer >= max_reposition_time:
		saki.set_move_direction(0.0)
		_start_attack()
		return

	current_state = BossState.CHASE

	var distance_x: float = player.global_position.x - saki.global_position.x
	var distance_y: float = saki.global_position.y - player.global_position.y

	if planned_attack in FAR_ATTACKS:
		saki.set_move_direction(signf(reposition_target_x - saki.global_position.x))
		return

	saki.set_move_direction(signf(distance_x))

	# Jump if Mayumi is above Saki
	if distance_y > 60.0 and saki.is_on_floor():
		saki.jump()


func _get_far_corner_x() -> float:
	if saki.global_position.x >= player.global_position.x:
		return arena_right_x

	return arena_left_x


func _is_in_position() -> bool:
	if planned_attack in FAR_ATTACKS:
		return absf(saki.global_position.x - reposition_target_x) <= arrive_tolerance

	if planned_attack in CLOSE_ATTACKS:
		var distance_x: float = player.global_position.x - saki.global_position.x
		var distance_y: float = saki.global_position.y - player.global_position.y

		return absf(distance_x) <= close_range \
			and absf(distance_y) <= attack_height_tolerance

	return true


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

	var attack_id := planned_attack
	planned_attack = ""

	print("Saki selected: ", attack_id)

	await _telegraph()

	if not is_inside_tree() or saki == null or saki.defeated:
		return

	if attack_manager == null:
		push_error("BossAI: AttackManager reference is missing.")
		is_attacking = false
		return

	await attack_manager.execute_attack(attack_id)

	if not is_inside_tree() or saki == null or saki.defeated:
		return

	is_attacking = false

	await get_tree().create_timer(attack_cooldown).timeout

	if not is_inside_tree() or saki == null or saki.defeated:
		return

	attack_ready = true



func _telegraph() -> void:
	if sprite == null or telegraph_time <= 0.0:
		return

	var base_color := sprite.modulate

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", telegraph_color, telegraph_time * 0.5)
	tween.tween_property(sprite, "modulate", base_color, telegraph_time * 0.5)

	await tween.finished


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
