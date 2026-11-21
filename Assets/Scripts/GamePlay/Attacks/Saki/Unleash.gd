
extends BossAttack

@export_group("Visual Assets")
@export var projectile_scene: PackedScene
@export var arena_center: Marker2D
@export var burst_effect_scene: PackedScene

@export_group("Attack")
@export var preparation_time: float = 1.0
@export var recovery_time: float = 1.0
@export var damage: int = 10

@export_group("Movement")
@export var movement_speed: float = 300.0
@export var arrival_tolerance: float = 5.0

@export_group("Projectile")
@export var projectile_speed: float = 350.0
@export var projectile_lifetime: float = 4.0
@export var launch_offset: float = 35.0

@export_group("Firing Pattern")
@export_range(1, 64) var projectile_count: int = 16
@export_range(1, 10) var wave_count: int = 2
@export var wave_angle_offset: float = 11.25
@export var wave_interval: float = 0.5


var burst_effect: Node2D


func execute() -> void:
	if saki == null or player == null:
		push_warning("Unleash: Missing Saki or player reference.")
		return

	if projectile_scene == null:
		push_warning("Unleash: Assign a projectile scene.")
		return

	if arena_center == null:
		push_warning("Unleash: Assign the arena center Marker2D.")
		return

	# Stop Saki's normal movement.
	saki.set_move_direction(0.0)

	print("Saki prepares Unleash!")

	# Make sure Saki is on the ground.
	var landed: bool = await _force_land()

	if not landed or saki.defeated:
		return

	saki.velocity = Vector2.ZERO
	saki.set_physics_process(false)

	# Move to the arena center.
	var reached_center: bool = await _move_to_center()

	if not reached_center or saki.defeated:
		_finish_attack()
		return

	print("Saki reached the center of the arena!")

	# Spawn optional charge-up effect.
	_spawn_burst_effect()

	# Preparation.
	await get_tree().create_timer(preparation_time).timeout

	if saki.defeated:
		_finish_attack()
		return

	print("Saki unleashes her danmaku!")

	# Fire successive radial waves.
	for wave in range(wave_count):
		if saki.defeated:
			break

		_fire_wave(wave)

		if wave < wave_count - 1:
			await get_tree().create_timer(wave_interval).timeout

	if not saki.defeated:
		print("Saki is recovering!")
		await get_tree().create_timer(recovery_time).timeout

	_finish_attack()


func _force_land() -> bool:
	while not saki.is_on_floor():
		if saki.defeated:
			return false

		saki.velocity.y = 600.0
		await get_tree().physics_frame

	return true


func _move_to_center() -> bool:
	var target_x := arena_center.global_position.x

	while absf(saki.global_position.x - target_x) > arrival_tolerance:
		if saki.defeated:
			return false

		await get_tree().physics_frame

		var delta := 1.0 / float(Engine.physics_ticks_per_second)

		var difference := target_x - saki.global_position.x
		var direction := signf(difference)

		var distance := minf(
			absf(difference),
			movement_speed * delta
		)

		var motion := Vector2(direction * distance, 0.0)

		var collision := saki.move_and_collide(motion)

		if collision != null:
			push_warning("Unleash: Saki could not reach the arena center.")
			return false

	return true


func _spawn_burst_effect() -> void:
	if burst_effect_scene == null:
		return

	burst_effect = burst_effect_scene.instantiate() as Node2D

	if burst_effect == null:
		push_warning("Unleash: Burst effect root must be Node2D.")
		return

	saki.add_child(burst_effect)
	burst_effect.position = Vector2.ZERO


func _fire_wave(wave_index: int) -> void:
	var world := get_tree().current_scene

	var angle_offset := wave_angle_offset * wave_index

	for i in range(projectile_count):
		if saki.defeated:
			return

		var angle := (
			360.0 * float(i) / float(projectile_count)
		) + angle_offset

		var direction := Vector2.RIGHT.rotated(deg_to_rad(angle))

		var projectile := projectile_scene.instantiate() as NormalDanmakuProjectile

		if projectile == null:
			push_warning("Unleash: Invalid projectile scene.")
			continue

		projectile.setup(
			player,
			direction,
			projectile_speed,
			damage,
			projectile_lifetime,
			CharacterStats.DamagePhase.PHASE_2
		)

		world.add_child(projectile)

		projectile.global_position = (
			saki.global_position + direction * launch_offset
		)

	print("Unleash wave ", wave_index + 1, " fired!")


func _finish_attack() -> void:
	if is_instance_valid(burst_effect):
		burst_effect.queue_free()

	burst_effect = null

	if not saki.defeated:
		saki.velocity = Vector2.ZERO
		saki.set_physics_process(true)

	print("Unleash finished!")
