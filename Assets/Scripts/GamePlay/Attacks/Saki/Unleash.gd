
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
@export var hop_height: float = 40.0

@export_group("Projectile")
@export var projectile_speed: float = 350.0
@export var projectile_lifetime: float = 4.0
@export var launch_offset: float = 35.0

@export_group("Firing Pattern")
@export_range(1, 64) var projectile_count: int = 16
@export_range(1, 10) var wave_count: int = 2
@export var wave_angle_offset: float = 11.25
@export var wave_interval: float = 0.5

@export_group("Telegraph")
@export var pulse_count: int = 3
@export var pulse_color: Color = Color(2.0, 1.4, 1.4)

var burst_effect: Node2D
var is_unleashing: bool

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
	is_unleashing = true;
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

	await _pulse(preparation_time)

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
			if not is_inside_tree():
				return

			await get_tree().create_timer(wave_interval).timeout

			if not is_inside_tree():
				return

	if not saki.defeated:
		print("Saki is recovering!")
		if not is_inside_tree():
			return

		await get_tree().create_timer(recovery_time).timeout

		if not is_inside_tree():
			return

	_finish_attack()


func _force_land() -> bool:
	while not saki.is_on_floor():
		if saki.defeated:
			return false

		saki.velocity.y = 600.0
		if not is_inside_tree():
			return false

		await get_tree().physics_frame

		if not is_inside_tree():
			return false

	return true


func _move_to_center() -> bool:
	var origin := saki.global_position
	var destination := Vector2(arena_center.global_position.x, origin.y)

	var distance := absf(destination.x - origin.x)

	if distance <= arrival_tolerance:
		return true

	var duration := maxf(distance / movement_speed, 0.15)
	var elapsed := 0.0

	while elapsed < duration:
		if not is_inside_tree():
			return false

		await get_tree().physics_frame

		if not is_inside_tree():
			return false

		if saki.defeated:
			return false

		elapsed += 1.0 / float(Engine.physics_ticks_per_second)

		var weight := clampf(elapsed / duration, 0.0, 1.0)
		var hop_position := origin.lerp(destination, weight)
		hop_position.y -= sin(weight * PI) * hop_height

		saki.global_position = hop_position

	saki.global_position = destination

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


func _pulse(duration: float) -> void:
	var sprite := saki.get_node_or_null("Saki") as CanvasItem

	if sprite == null or pulse_count <= 0:
		if not is_inside_tree():
			return

		await get_tree().create_timer(duration).timeout

		if not is_inside_tree():
			return
		return

	var base_color := sprite.modulate
	var step := duration / float(pulse_count * 2)

	var tween := create_tween()

	for i in range(pulse_count):
		tween.tween_property(sprite, "modulate", pulse_color, step)
		tween.tween_property(sprite, "modulate", base_color, step)

	await tween.finished


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
	Sfx.play("fire_burst", 2.0, 0.9)


func _finish_attack() -> void:
	if is_instance_valid(burst_effect):
		burst_effect.queue_free()

	burst_effect = null
	is_unleashing = false
	if not saki.defeated:
		saki.velocity = Vector2.ZERO
		saki.set_physics_process(true)

	print("Unleash finished!")
