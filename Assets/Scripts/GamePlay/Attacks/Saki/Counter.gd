extends BossAttack

signal counter_ready_changed(is_ready: bool)
signal counter_performed

@export_group("Counter")
@export var stance_duration: float = 1.6
@export var teleport_distance: float = 45.0
@export var strike_delay: float = 0.12
@export var recovery_time: float = 0.6
@export var counter_damage: int = 20

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

	print("Saki takes a counter stance!")

	var elapsed := 0.0

	while elapsed < stance_duration and not triggered:
		if saki.defeated:
			break

		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()

	is_posing = false
	counter_ready_changed.emit(false)

	if saki.defeated:
		return

	if triggered:
		await _perform_counter()
	else:
		print("Saki drops her stance.")

	if not saki.defeated:
		await get_tree().create_timer(recovery_time, false).timeout


func _on_physical_attack_started() -> void:
	if is_posing:
		triggered = true


func _perform_counter() -> void:
	print("Saki countered Mayumi!")

	var facing_direction: float = float(player.get("facing_direction"))

	var teleport_x := clampf(
		player.global_position.x - facing_direction * teleport_distance,
		arena_left_x,
		arena_right_x
	)

	saki.global_position = Vector2(teleport_x, saki.global_position.y)
	saki.velocity = Vector2.ZERO

	await get_tree().create_timer(strike_delay, false).timeout

	if saki.defeated:
		return

	var player_stats := player.get_node_or_null("Stats") as CharacterStats

	if player_stats != null:
		player_stats.take_damage(counter_damage)

	counter_performed.emit()
