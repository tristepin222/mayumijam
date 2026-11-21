
extends PlayerAbility

@export_group("Projectile")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var projectile_damage: int = 10
@export var projectile_lifetime: float = 4.0
@export var projectile_offset: Vector2 = Vector2(35.0, 0.0)

@export_group("Attack")
@export var cooldown: float = 0.5
@export var volley_charge_time: float = 0.4

var can_shoot := true
var is_charging := false
var charge_started_at := 0.0

const VOLLEY_ANGLES := [-30.0, -15.0, 0.0, 15.0, 30.0]


func _ready() -> void:

ability_id = AbilityIDs.Ability.DANMAKU

func has_arrow_volley() -> bool:
	return ability_manager.has_ability(AbilityIDs.Ability.ARROW_VOLLEY)

# Called when the player presses the Danmaku button.
func start_charge() -> void:
	# Without Arrow Volley, fire a normal projectile.
	if not has_arrow_volley():
		activate()
		return

	if not can_activate() or not can_shoot:
		return

	if projectile_scene == null:
		push_warning("DanmakuShot: Assign a projectile scene.")
		return

	is_charging = true
	can_shoot = false
	charge_started_at = Time.get_ticks_msec() / 1000.0

	print("Charging Arrow Volley...")


# Called when the player releases the Danmaku button.
func release_charge() -> void:
	if not is_charging:
		return

	is_charging = false

	ability_manager.use_ability(ability_id)

	var held_time := Time.get_ticks_msec() / 1000.0 - charge_started_at

	if held_time >= volley_charge_time:
		for angle in VOLLEY_ANGLES:
			var direction := Vector2(
				mayumi.facing_direction,
				0.0
			).rotated(deg_to_rad(angle))

			_spawn_projectile(direction)

		print("Mayumi fired Arrow Volley!")
	else:
		_spawn_projectile(Vector2(mayumi.facing_direction, 0.0))

	await get_tree().create_timer(cooldown).timeout
	can_shoot = true


# Normal single projectile attack.
func activate() -> void:
	if not can_activate() or not can_shoot:
		return

	if projectile_scene == null:
		push_warning("DanmakuShot: Assign a projectile scene.")
		return

	ability_manager.use_ability(ability_id)
	can_shoot = false

	_spawn_projectile(Vector2(mayumi.facing_direction, 0.0))

	await get_tree().create_timer(cooldown).timeout
	can_shoot = true


func _spawn_projectile(direction: Vector2) -> void:
	var projectile := projectile_scene.instantiate() as Area2D

	if projectile == null:
		push_warning("DanmakuShot: Projectile root must be Area2D.")
		return

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
