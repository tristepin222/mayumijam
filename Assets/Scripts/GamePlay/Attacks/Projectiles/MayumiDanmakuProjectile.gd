
class_name MayumiDanmakuProjectile
extends Area2D

@export_group("Projectile")
@export var speed: float = 400.0
@export var lifetime: float = 4.0
@export var damage: int = 10

var direction: Vector2 = Vector2.RIGHT
var has_hit := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(
		launch_direction: Vector2,
		projectile_speed: float,
		projectile_damage: int,
		projectile_lifetime: float
) -> void:
	direction = launch_direction.normalized()
	speed = projectile_speed
	damage = projectile_damage
	lifetime = projectile_lifetime
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if has_hit or not body.is_in_group("enemies"):
		return

	has_hit = true

	var enemy_stats := body.get_node_or_null("Stats") as CharacterStats

	if enemy_stats != null:
		enemy_stats.take_damage(damage)
		print("Saki was hit by Mayumi's Danmaku!")

	queue_free()
