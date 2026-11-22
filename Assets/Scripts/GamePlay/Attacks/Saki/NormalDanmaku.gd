
extends BossAttack

@export_group("Visual Assets")
@export var projectile_scene: PackedScene

@export_group("Attack")
@export var preparation_time: float = 0.5
@export var recovery_time: float = 0.7

@export_group("Projectile")
@export var projectile_speed: float = 400.0
@export var projectile_lifetime: float = 4.0
@export var projectile_damage: int = 10

@export_group("Firing Pattern")
@export_range(1, 20) var projectile_count: int = 5
@export var spread_angle: float = 45.0
@export_range(1, 10) var volley_count: int = 1
@export var volley_interval: float = 0.35
@export var launch_offset: float = 35.0

var is_casting: bool

func execute() -> void:
	if saki == null or player == null:
		push_warning("Normal Danmaku: Missing Saki or player reference.")
		return

	if projectile_scene == null:
		push_warning("Normal Danmaku: Assign a projectile scene.")
		return

	saki.set_move_direction(0.0)
	is_casting = true
	print("Saki prepares Normal Danmaku!")

	if not is_inside_tree():
		return

	await get_tree().create_timer(preparation_time).timeout

	if not is_inside_tree():
		return

	if saki.defeated:
		return

	for volley in range(volley_count):
		if saki.defeated:
			return

		_fire_volley(volley)

		if volley < volley_count - 1:
			if not is_inside_tree():
				return

			await get_tree().create_timer(volley_interval).timeout

			if not is_inside_tree():
				return

	if not saki.defeated:
		print("Saki is recovering!")
		if not is_inside_tree():
			return

		await get_tree().create_timer(recovery_time).timeout

		if not is_inside_tree():
			return

	print("Normal Danmaku finished!")


func _fire_volley(volley_index: int = 0) -> void:
	var world := get_tree().current_scene

	var base_direction := (
		player.global_position - saki.global_position
	).normalized()

	if volley_index % 2 == 1 and projectile_count > 1:
		var half_gap := spread_angle / float(projectile_count - 1) / 2.0
		base_direction = base_direction.rotated(deg_to_rad(half_gap))

	var first_angle := -spread_angle / 2.0

	for i in range(projectile_count):
		var angle := 0.0

		if projectile_count > 1:
			angle = first_angle + (
				spread_angle * float(i) / float(projectile_count - 1)
			)

		var direction := base_direction.rotated(deg_to_rad(angle))

		var projectile := projectile_scene.instantiate() as NormalDanmakuProjectile

		if projectile == null:
			push_warning("Normal Danmaku: Projectile scene has the wrong root or script.")
			continue

		projectile.setup(
			player,
			direction,
			projectile_speed,
			projectile_damage,
			projectile_lifetime
		)

		world.add_child(projectile)

		projectile.global_position = saki.global_position + direction * launch_offset
	is_casting = false
	print("Saki fired a volley of ", projectile_count, " projectiles!")
