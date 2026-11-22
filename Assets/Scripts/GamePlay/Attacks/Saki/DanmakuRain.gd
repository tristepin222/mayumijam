extends BossAttack

@export_group("Visual Assets")
@export var projectile_scene: PackedScene
@export var warning_scene: PackedScene

@export_group("Toss")
@export var toss_count: int = 6
@export var toss_speed: float = 420.0
@export var toss_time: float = 0.35
@export var drop_delay: float = 0.35

@export_group("Rain")
@export var rain_count: int = 7
@export var fall_speed: float = 150.0
@export var spawn_height: float = 190.0
@export var stagger_time: float = 0.5
@export var damage: int = 1
@export var ground_offset: float = 20.0
@export var arena_left_x: float = -130.0
@export var arena_right_x: float = 178.0

@export_group("Melee")
@export var lunge_count: int = 2
@export var lunge_windup: float = 0.35
@export var lunge_distance: float = 110.0
@export var lunge_speed: float = 420.0
@export var lunge_damage: int = 1
@export var between_lunges: float = 0.2
@export var flash_color: Color = Color(2.0, 0.6, 0.6)

@export_group("Recovery")
@export var recovery_time: float = 0.7


func execute() -> void:
	if saki == null or player == null:
		push_warning("Danmaku Rain: Missing Saki or player reference.")
		return

	if projectile_scene == null:
		push_warning("Danmaku Rain: Assign a projectile scene.")
		return

	saki.set_move_direction(0.0)

	var landed: bool = await _force_land()

	if not landed or saki.defeated:
		return

	saki.velocity = Vector2.ZERO
	saki.set_physics_process(false)

	print("Saki tosses danmaku into the air!")

	var ground_y := saki.global_position.y + ground_offset

	_toss()

	await get_tree().create_timer(toss_time + drop_delay, false).timeout

	if saki.defeated:
		_finish_attack()
		return

	_start_rain(ground_y)

	for i in range(lunge_count):
		if saki.defeated:
			break

		await _flash(lunge_windup)

		if saki.defeated:
			break

		await _lunge()

		if i < lunge_count - 1:
			await get_tree().create_timer(between_lunges, false).timeout

	if not saki.defeated:
		await get_tree().create_timer(recovery_time, false).timeout

	_finish_attack()


func _force_land() -> bool:
	while not saki.is_on_floor():
		if saki.defeated:
			return false

		saki.velocity.y = 600.0
		await get_tree().physics_frame

	return true


func _toss() -> void:
	var world := get_tree().current_scene

	for i in range(toss_count):
		var projectile := projectile_scene.instantiate() as Area2D

		if projectile == null:
			continue

		world.add_child(projectile)
		projectile.global_position = saki.global_position

		var spread := randf_range(-90.0, 90.0)

		projectile.call(
			"setup",
			player,
			Vector2(spread, -toss_speed),
			0,
			INF,
			toss_time + drop_delay,
			true
		)


func _start_rain(ground_y: float) -> void:
	var xs: Array[float] = []

	for i in range(rain_count):
		var weight := (float(i) + 0.5) / float(rain_count)
		var x := lerpf(arena_left_x, arena_right_x, weight) + randf_range(-10.0, 10.0)
		xs.append(x)

	var player_x := clampf(player.global_position.x, arena_left_x, arena_right_x)
	var closest := 0

	for i in range(xs.size()):
		if absf(xs[i] - player_x) < absf(xs[closest] - player_x):
			closest = i

	xs[closest] = player_x

	for x in xs:
		_drop_one(x, randf_range(0.0, stagger_time), ground_y)


func _drop_one(x: float, delay: float, ground_y: float) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout

	if not is_inside_tree():
		return

	var world := get_tree().current_scene

	var warning: Node2D = null

	if warning_scene != null:
		warning = warning_scene.instantiate() as Node2D
		world.add_child(warning)
		warning.global_position = Vector2(x, ground_y)

	var projectile := projectile_scene.instantiate() as Area2D

	if projectile == null:
		if is_instance_valid(warning):
			warning.queue_free()
		return

	world.add_child(projectile)
	projectile.global_position = Vector2(x, ground_y - spawn_height)

	projectile.call(
		"setup",
		player,
		Vector2(0.0, fall_speed),
		damage,
		ground_y
	)

	if warning != null:
		projectile.tree_exited.connect(warning.queue_free)


func _flash(duration: float) -> void:
	var sprite := saki.get_node_or_null("Sprite2D") as CanvasItem

	if sprite == null or duration <= 0.0:
		await get_tree().create_timer(maxf(duration, 0.0), false).timeout
		return

	var base_color := sprite.modulate

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", flash_color, duration * 0.5)
	tween.tween_property(sprite, "modulate", base_color, duration * 0.5)

	await tween.finished


func _lunge() -> void:
	var direction := signf(player.global_position.x - saki.global_position.x)

	if direction == 0.0:
		direction = 1.0

	print("Saki lunges with a kick!")

	var travelled := 0.0

	while travelled < lunge_distance:
		await get_tree().physics_frame

		if saki.defeated:
			return

		var delta := 1.0 / float(Engine.physics_ticks_per_second)
		var motion := Vector2(direction * lunge_speed * delta, 0.0)

		var collision := saki.move_and_collide(motion)
		travelled += motion.length()

		if collision != null:
			if collision.get_collider() == player:
				var player_stats := player.get_node_or_null("Stats") as CharacterStats

				if player_stats != null:
					player_stats.take_damage(lunge_damage)
					print("Saki's lunge hit Mayumi!")

			return


func _finish_attack() -> void:
	if not saki.defeated:
		saki.velocity = Vector2.ZERO
		saki.set_physics_process(true)

	print("Danmaku Rain finished!")
