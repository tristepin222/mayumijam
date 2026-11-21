
class_name NormalDanmakuProjectile
extends Area2D

@export_group("Projectile")
@export var speed: float = 400.0
@export var lifetime: float = 4.0
@export var damage: int = 10

var direction: Vector2 = Vector2.RIGHT
var target_player: CharacterBody2D
var has_hit := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(
		target: CharacterBody2D,
		launch_direction: Vector2,
		projectile_speed: float,
		projectile_damage: int,
		projectile_lifetime: float
) -> void:
	target_player = target
	direction = launch_direction.normalized()
	speed = projectile_speed
	damage = projectile_damage
	lifetime = projectile_lifetime


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if has_hit or body != target_player:
		return

	if target_player.is_grazing_projectiles:
		return

	has_hit = true

	var player_stats := target_player.get_node_or_null("Stats") as CharacterStats

	if player_stats != null:
		player_stats.take_damage(damage)
		print("Mayumi was hit by Normal Danmaku!")

	queue_free()
