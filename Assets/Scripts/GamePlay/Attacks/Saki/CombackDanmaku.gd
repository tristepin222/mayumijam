
extends BossAttack

@export_group("Visual Assets")
@export var projectile_scene: PackedScene

@export_group("Attack")
@export var preparation_time: float = 0.5
@export var recovery_time: float = 0.7
@export var damage: int = 15

@export_group("Projectile")
@export var outward_speed: float = 450.0
@export var return_speed: float = 550.0
@export var outward_distance: float = 450.0
@export var return_curve_height: float = 100.0

@export_group("Launch")
@export var launch_angle: float = 25.0
@export var launch_offset: float = 40.0

@export_group("Throw")
@export_range(1, 4) var throw_count: int = 2
@export var throw_interval: float = 0.45
@export var throw_height_offset: float = 10.0

var active_projectiles: int = 0


func execute() -> void:
	if saki == null or player == null:
		push_warning("Comeback Danmaku: Missing Saki or player reference.")
		return

	if projectile_scene == null:
		push_warning("Comeback Danmaku: Assign a projectile scene.")
		return

	saki.set_move_direction(0.0)

	var landed: bool = await _force_land()

	if not landed or saki.defeated:
		return

	saki.velocity = Vector2.ZERO
	saki.set_physics_process(false)

	print("Saki prepares Comeback Danmaku!")

	await get_tree().create_timer(preparation_time).timeout

	if saki.defeated:
		_finish_attack()
		return

	await _throw_projectiles()

	# Wait until both projectiles have returned.
	while active_projectiles > 0:
		if saki.defeated:
			_cleanup_projectiles()
			break

		await get_tree().physics_frame

	if is_inside_tree() and not saki.defeated:
		await get_tree().create_timer(recovery_time).timeout

	if is_inside_tree():
		_finish_attack()


func _force_land() -> bool:
	while not saki.is_on_floor():
		if saki.defeated:
			return false

		saki.velocity.y = 600.0
		await get_tree().physics_frame

	return true


func _throw_projectiles() -> void:
	var world := get_tree().current_scene

	active_projectiles = 0

	for i in range(throw_count):
		if saki.defeated:
			return

		var side := signf(player.global_position.x - saki.global_position.x)

		if side == 0.0:
			side = 1.0

		var direction := Vector2(side, 0.0)

		var projectile := projectile_scene.instantiate()

		if not projectile is Area2D:
			push_warning("Comeback Danmaku: Projectile root must be Area2D.")
			projectile.queue_free()
			continue

		world.add_child(projectile)

		projectile.global_position = saki.global_position + Vector2(
			side * launch_offset,
			throw_height_offset
		)

		projectile.damage = damage
		projectile.outward_speed = outward_speed
		projectile.return_speed = return_speed
		projectile.outward_distance = outward_distance
		projectile.return_curve_height = return_curve_height

		projectile.launch(saki, player, direction)

		projectile.tree_exited.connect(_on_projectile_removed)

		active_projectiles += 1

		print("Saki throws a comeback horseshoe! (", i + 1, "/", throw_count, ")")

		if i < throw_count - 1:
			await get_tree().create_timer(throw_interval, false).timeout


func _on_projectile_removed() -> void:
	active_projectiles = maxi(active_projectiles - 1, 0)


func _cleanup_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("comeback_projectiles"):
		projectile.queue_free()

	active_projectiles = 0


func _finish_attack() -> void:
	if not saki.defeated:
		saki.velocity = Vector2.ZERO
		saki.set_physics_process(true)

	print("Comeback Danmaku finished!")
