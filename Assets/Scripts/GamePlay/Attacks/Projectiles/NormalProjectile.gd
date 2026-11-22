
class_name NormalDanmakuProjectile
extends Area2D

@export_group("Projectile")
@export var speed: float = 400.0
@export var lifetime: float = 4.0
@export var damage: int = 10

var direction: Vector2 = Vector2.RIGHT
var target_player: CharacterBody2D
var has_hit := false
var is_reflected := false
var damage_phase: CharacterStats.DamagePhase = CharacterStats.DamagePhase.PHASE_1

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(
		target: CharacterBody2D,
		launch_direction: Vector2,
		projectile_speed: float,
		projectile_damage: int,
		projectile_lifetime: float,
		phase: CharacterStats.DamagePhase = CharacterStats.DamagePhase.PHASE_1
) -> void:
	target_player = target
	direction = launch_direction.normalized()
	speed = projectile_speed
	damage = projectile_damage
	lifetime = projectile_lifetime
	damage_phase = phase


func reflect(saki: Node2D) -> void:
	if has_hit or is_reflected:
		return

	is_reflected = true
	target_player = saki as CharacterBody2D

	if target_player == null:
		queue_free()
		return

	direction = (
		target_player.global_position - global_position
	).normalized()

	# Give the reflected projectile a fresh lifetime.
	lifetime = 4.0

	print("Normal Danmaku reflected towards Saki!")


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if has_hit or body != target_player:
		return

	if not is_reflected and target_player.is_grazing_projectiles:
		return

	has_hit = true

	var target_stats := target_player.get_node_or_null("Stats") as CharacterStats

	if target_stats != null:
		target_stats.take_damage(damage, damage_phase)

		if is_reflected:
			print("Reflected Danmaku hit Saki!")
		else:
			print("Mayumi was hit by Normal Danmaku!")

	queue_free()
