
extends Node

signal counter_ready_changed(is_ready: bool)
signal counter_performed

@export_group("Counter")
@export var cooldown_duration: float = 4.0
@export var teleport_distance: float = 80.0
@export var counter_damage: int = 20

var saki: SakiController
var player: CharacterBody2D

var can_counter := true


func _ready() -> void:
	saki = get_parent() as SakiController

	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if player == null:
		push_warning("Counter: Could not find player.")
		return

	if not player.has_signal("physical_attack_started"):
		push_warning("Counter: Player has no physical_attack_started signal.")
		return

	player.connect("physical_attack_started", _on_physical_attack_started)

	counter_ready_changed.emit(true)


func _on_physical_attack_started() -> void:
	if not can_counter:
		return

	if saki == null or saki.defeated:
		return

	# Prevent another counter until the cooldown expires.
	can_counter = false
	counter_ready_changed.emit(false)

	_perform_counter()

	_start_cooldown()


func _perform_counter() -> void:
	print("Saki countered Mayumi!")

	# Teleport behind Mayumi.
	var facing_direction: float = float(player.get("facing_direction"))
	var direction_behind := -facing_direction

	var teleport_position := player.global_position
	teleport_position.x += direction_behind * teleport_distance

	saki.global_position = teleport_position

	# Damage Mayumi.
	var player_stats := player.get_node_or_null("Stats") as CharacterStats

	if player_stats != null:
		player_stats.take_damage(counter_damage)

	counter_performed.emit()


func _start_cooldown() -> void:
	await get_tree().create_timer(cooldown_duration).timeout

	if saki == null or saki.defeated:
		return

	can_counter = true
	counter_ready_changed.emit(true)

	print("Saki's counter is ready again!")
