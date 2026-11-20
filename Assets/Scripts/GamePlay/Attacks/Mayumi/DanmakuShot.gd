
extends PlayerAbility

@export_group("Projectile")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var projectile_damage: int = 10
@export var projectile_lifetime: float = 4.0
@export var projectile_offset: Vector2 = Vector2(35.0, 0.0)

@export_group("Attack")
@export var cooldown: float = 0.5

var can_shoot := true


func _ready() -> void:
	ability_id = "danmaku_shot"


func activate() -> void:
	if not can_activate():
		return

	if not can_shoot:
		return

	if projectile_scene == null:
		push_warning("DanmakuShot: Assign a projectile scene.")
		return

	ability_manager.use_ability(ability_id)

	can_shoot = false

	_spawn_projectile()

	await get_tree().create_timer(cooldown).timeout

	can_shoot = true


func _spawn_projectile() -> void:
	var projectile := projectile_scene.instantiate() as Area2D

	if projectile == null:
		push_warning("DanmakuShot: Projectile root must be Area2D.")
		return

	var direction := Vector2(mayumi.facing_direction, 0.0)

	get_tree().current_scene.add_child(projectile)

	projectile.global_position = mayumi.global_position + Vector2(
		absf(projectile_offset.x) * mayumi.facing_direction,
		projectile_offset.y
	)

	projectile.call(
		"setup",
		direction,
		projectile_speed,
		projectile_damage,
		projectile_lifetime
	)
