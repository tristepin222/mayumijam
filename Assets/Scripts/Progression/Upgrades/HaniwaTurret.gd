
extends Node2D

@export_group("Combat")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var projectile_damage: int = 8
@export var fire_interval: float = 0.8
@export var duration: float = 6.0

var saki: SakiController
var active := false


func setup(enemy: SakiController) -> void:
	saki = enemy


func _ready() -> void:
	$Timer.wait_time = fire_interval
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start()

	active = true
	_run_lifetime()


func _run_lifetime() -> void:
	await get_tree().create_timer(duration).timeout

	if is_instance_valid(self):
		queue_free()


func _on_timer_timeout() -> void:
	if not active or not is_instance_valid(saki):
		return

	if projectile_scene == null:
		return

	_fire_projectile()


func _fire_projectile() -> void:
	var projectile := projectile_scene.instantiate() as Area2D

	if projectile == null:
		return

	get_tree().current_scene.add_child(projectile)

	var direction := (
		saki.global_position - global_position
	).normalized()

	projectile.global_position = global_position

	projectile.call(
		"setup",
		direction,
		projectile_speed,
		projectile_damage,
		4.0
	)
