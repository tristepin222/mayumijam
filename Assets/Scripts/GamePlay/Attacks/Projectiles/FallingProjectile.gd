extends Area2D

@export var damage: int = 1

var velocity := Vector2.ZERO
var target_player: CharacterBody2D
var harmless := false
var lifetime := -1.0
var kill_y := INF
var has_hit := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(
		target: CharacterBody2D,
		start_velocity: Vector2,
		projectile_damage: int,
		ground_y: float = INF,
		life: float = -1.0,
		is_harmless: bool = false
) -> void:
	target_player = target
	velocity = start_velocity
	damage = projectile_damage
	kill_y = ground_y
	lifetime = life
	harmless = is_harmless


func _physics_process(delta: float) -> void:
	global_position += velocity * delta

	if lifetime > 0.0:
		lifetime -= delta

		if lifetime <= 0.0:
			queue_free()
			return

	if global_position.y >= kill_y:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if harmless or has_hit or body != target_player:
		return

	if target_player.get("is_grazing_projectiles"):
		if not has_meta("grazed"):
			set_meta("grazed", true)
			Sfx.play("graze")
		return

	has_hit = true

	var player_stats := target_player.get_node_or_null("Stats") as CharacterStats

	if player_stats != null:
		player_stats.take_damage(damage)
		print("Mayumi was hit by Danmaku Rain!")

	queue_free()
