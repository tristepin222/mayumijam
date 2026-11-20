
extends Area2D

signal returned_to_owner

@export_group("Movement")
@export var outward_speed: float = 450.0
@export var return_speed: float = 550.0
@export var outward_distance: float = 450.0
@export var return_curve_height: float = 100.0

@export_group("Combat")
@export var damage: int = 15

var owner_saki: Node2D
var target_player: CharacterBody2D

var direction: Vector2 = Vector2.RIGHT
var start_position: Vector2
var return_start_position: Vector2

var is_returning := false
var has_hit_player := false
var returning := false

var travel_distance := 0.0
var return_progress := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("comeback_projectiles")


func launch(
		saki: Node2D,
		player: CharacterBody2D,
		launch_direction: Vector2
) -> void:
	owner_saki = saki
	target_player = player
	direction = launch_direction.normalized()

	start_position = global_position

	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_saki):
		queue_free()
		return

	if not is_returning:
		_move_outward(delta)
	else:
		_move_returning(delta)


func _move_outward(delta: float) -> void:
	var movement := direction * outward_speed * delta
	global_position += movement

	travel_distance += movement.length()

	if travel_distance >= outward_distance:
		is_returning = true
		return_start_position = global_position
		return_progress = 0.0


func _move_returning(delta: float) -> void:
	var destination := owner_saki.global_position
	var distance := global_position.distance_to(destination)

	if distance <= return_speed * delta:
		returned_to_owner.emit()
		queue_free()
		return

	return_progress += return_speed * delta / maxf(
		return_start_position.distance_to(destination),
		1.0
	)

	var weight := clampf(return_progress, 0.0, 1.0)

	var midpoint := return_start_position.lerp(destination, weight)
	midpoint.y -= sin(weight * PI) * return_curve_height

	global_position = midpoint

	# Face the direction of travel.
	var next_direction := (destination - global_position).normalized()
	rotation = next_direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if body != target_player:
		return

	var player_stats := target_player.get_node_or_null("Stats") as CharacterStats

	if player_stats != null:
		player_stats.take_damage(damage)
