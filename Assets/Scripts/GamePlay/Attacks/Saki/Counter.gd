extends BossAttack

signal counter_ready_changed(is_ready: bool)
signal counter_performed

@export_group("Counter")
@export var stance_duration: float = 1.6
@export var teleport_distance: float = 45.0
@export var strike_delay: float = 0.12
@export var recovery_time: float = 0.6
@export var counter_damage: int = 20
@export var counter_reach: float = 55.0
@export var counter_reach_height: float = 45.0
@export var phase_2_counters_any_hit: bool = true

@export_group("Arena Limits")
@export var arena_left_x: float = -130.0
@export var arena_right_x: float = 178.0

var is_posing := false
var triggered := false


func _ready() -> void:
	var mayumi := get_tree().get_first_node_in_group("player")

	if mayumi == null:
		push_warning("Counter: Could not find player.")
		return

	if not mayumi.has_signal("physical_attack_started"):
		push_warning("Counter: Player has no physical_attack_started signal.")
		return

	mayumi.connect("physical_attack_started", _on_physical_attack_started)


func execute() -> void:
	if saki == null or player == null:
		push_warning("Counter: Missing Saki or player reference.")
		return

	saki.set_move_direction(0.0)

	is_posing = true
	triggered = false
	counter_ready_changed.emit(true)

	var saki_stats := saki.get_node_or_null("Stats") as CharacterStats

	if saki_stats != null and phase_2_counters_any_hit and _is_phase_2():
		saki_stats.damage_interceptor = _intercept_hit

	print("Saki takes a counter stance!")

	var elapsed := 0.0

	while elapsed < stance_duration and not triggered:
		if saki.defeated:
			break

		if not is_inside_tree():
			return

		await get_tree().physics_frame

		if not is_inside_tree():
			return
		elapsed += get_physics_process_delta_time()

	is_posing = false
	counter_ready_changed.emit(false)

	if saki_stats != null:
		saki_stats.damage_interceptor = Callable()

	if saki.defeated:
		return

	if triggered:
		await _perform_counter()
	else:
		print("Saki drops her stance.")

	if not saki.defeated:
		if not is_inside_tree():
			return

		await get_tree().create_timer(recovery_time, false).timeout

		if not is_inside_tree():
			return


func _on_physical_attack_started() -> void:
	if not is_posing or triggered:
		return

	if not _is_in_sword_reach():
		return

	triggered = true
	_teleport_behind_player()


func _intercept_hit(_amount: int) -> bool:
	if not is_posing or triggered:
		return false

	triggered = true
	_teleport_behind_player()
	return true


func _is_phase_2() -> bool:
	var boss_ai := saki.get_node_or_null("BossAi")

	if boss_ai == null:
		return false

	return int(boss_ai.get("current_phase")) == BossAI.BossPhase.PHASE_2


func _is_in_sword_reach() -> bool:
	if saki == null or player == null:
		return false

	var offset := saki.global_position - player.global_position

	if absf(offset.y) > counter_reach_height:
		return false

	if absf(offset.x) <= 10.0:
		return true

	var facing_direction: float = float(player.get("facing_direction"))

	return signf(offset.x) == signf(facing_direction) and absf(offset.x) <= counter_reach


func _teleport_behind_player() -> void:
	print("Saki countered Mayumi!")

	var facing_direction: float = float(player.get("facing_direction"))

	var teleport_x := clampf(
		player.global_position.x - facing_direction * teleport_distance,
		arena_left_x,
		arena_right_x
	)

	saki.global_position = Vector2(teleport_x, saki.global_position.y)
	saki.velocity = Vector2.ZERO


func _perform_counter() -> void:
	if not is_inside_tree():
		return

	await get_tree().create_timer(strike_delay, false).timeout

	if not is_inside_tree():
		return

	if saki.defeated:
		return

	var player_stats := player.get_node_or_null("Stats") as CharacterStats

	if player_stats != null:
		player_stats.take_damage(counter_damage)

	counter_performed.emit()
