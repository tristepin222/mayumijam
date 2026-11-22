
extends BossAttack

@export_group("Dive")
@export var preparation_time: float = 0.6
@export var launch_height: float = 180.0
@export var launch_duration: float = 0.3
@export var dive_speed: float = 650.0
@export var dive_arc_height: float = 100.0
@export var recovery_time: float = 0.5
@export var dive_damage: int = 20
@export var max_target_adjustment: float = 150.0

@export_group("Impact Zone")
@export var impact_damage: int = 1
@export var impact_width: float = 96.0
@export var impact_height: float = 28.0
@export var impact_duration: float = 0.3
@export var impact_color: Color = Color(1.0, 0.35, 0.1, 0.55)

@export_group("Ground Break")
@export var break_delay: float = 0.05
@export var break_width: float = 176.0
@export var break_height: float = 16.0
@export var break_duration: float = 0.35
@export var break_color: Color = Color(0.55, 0.3, 0.15, 0.7)

@export_group("Rocks")
@export var rock_spacing: float = 16.0
@export var rock_height_scale: float = 1.15
@export var rock_shockwave_time: float = 0.12
@export_range(0.0, 1.0) var zone_flash_opacity: float = 0.35

@export_group("Telegraph")
@export var flash_interval: float = 0.1
@export var flash_count: int = 3
@export var flash_color: Color = Color.RED

@export_group("Visual Assets")
@export var warning_scene: PackedScene
@export var warning_ground_offset: float = 32.0

var landing_warning: Node2D

var sprite: CanvasItem
var original_modulate: Color

var hitbox: Area2D

var start_position: Vector2
var target_position: Vector2

var has_hit_player := false


func execute() -> void:
	if saki == null or player == null:
		push_warning("Dive: Missing Saki or player reference.")
		return

	hitbox = saki.get_node_or_null("DiveHitbox") as Area2D
	sprite = saki.get_node_or_null("Saki") as CanvasItem

	if hitbox == null:
		push_error("Dive: Could not find DiveHitBox under Saki!")
		return

	if sprite != null:
		original_modulate = sprite.modulate

	# Stop horizontal movement, but keep normal physics enabled.
	saki.set_move_direction(0.0)

	# Force Saki to land before starting the attack.
	print("Saki is forcing herself to the ground!")

	var landed: bool = await _force_land()

	if not landed or saki.defeated:
		return

	# Take control of Saki's movement.
	saki.velocity = Vector2.ZERO
	saki.set_physics_process(false)

	hitbox.set_deferred("monitoring", false)
	has_hit_player = false

	start_position = saki.global_position
	target_position = player.global_position

	print("Saki is preparing to dive!")

	# Telegraph.
	await _telegraph()

	if saki.defeated:
		_finish_attack()
		return

	# Adjust the target based on Mayumi's latest position.
	target_position = _get_adjusted_target()
	
	_show_landing_warning()

	# Takeoff.
	var launch_position := start_position
	launch_position.y -= launch_height

	print("Saki is launching!")
	Sfx.play("dash", 2.0, 0.65)

	var launch_completed: bool = await _move_to_position(
		launch_position,
		launch_duration
	)

	if not launch_completed or saki.defeated:
		_finish_attack()
		return

	print("Saki is diving!")

	hitbox.set_deferred("monitoring", true)

	var dive_completed: bool = await _perform_dive()

	if saki.defeated:
		_finish_attack()
		return

	if not is_inside_tree():
		return

	await get_tree().physics_frame

	if not is_inside_tree():
		return
	_check_hit()

	if dive_completed:
		await _impact_zone(impact_width, impact_height, impact_duration, impact_color)

		if not saki.defeated and break_width > 0.0:
			if not is_inside_tree():
				return

			await get_tree().create_timer(break_delay, false).timeout

			if not is_inside_tree():
				return
			await _impact_zone(break_width, break_height, break_duration, break_color)

	hitbox.set_deferred("monitoring", false)
	_remove_landing_warning()

	if dive_completed:
		print("Saki landed!")
	else:
		print("Saki's dive was interrupted!")

	# Recovery.
	print("Saki is recovering!")

	if not is_inside_tree():
		return

	await get_tree().create_timer(recovery_time).timeout

	if not is_inside_tree():
		return

	_finish_attack()

	print("Saki finished her dive!")


func _force_land() -> bool:
	while not saki.is_on_floor():
		if saki.defeated:
			return false

		# Force Saki downward.
		saki.velocity.y = 600.0

		# Let Saki's normal physics update her position.
		if not is_inside_tree():
			return false

		await get_tree().physics_frame

		if not is_inside_tree():
			return false

	return true


func _get_adjusted_target() -> Vector2:
	var current_player_position := player.global_position

	var horizontal_difference := current_player_position.x - target_position.x

	horizontal_difference = clampf(
		horizontal_difference,
		-max_target_adjustment,
		max_target_adjustment
	)

	return Vector2(
		target_position.x + horizontal_difference,
		start_position.y
	)


func _telegraph() -> void:
	if sprite == null or flash_count <= 0:
		if not is_inside_tree():
			return

		await get_tree().create_timer(preparation_time).timeout

		if not is_inside_tree():
			return
		return

	var interval := preparation_time / float(flash_count * 2)

	for i in range(flash_count):
		if saki.defeated:
			return

		sprite.modulate = flash_color
		if not is_inside_tree():
			return

		await get_tree().create_timer(interval).timeout

		if not is_inside_tree():
			return

		if saki.defeated:
			return

		sprite.modulate = original_modulate
		if not is_inside_tree():
			return

		await get_tree().create_timer(interval).timeout

		if not is_inside_tree():
			return

	sprite.modulate = original_modulate


func _move_to_position(destination: Vector2, duration: float) -> bool:
	var origin := saki.global_position
	var elapsed := 0.0

	if duration <= 0.0:
		return true

	while elapsed < duration:
		if not is_inside_tree():
			return false

		await get_tree().physics_frame

		if not is_inside_tree():
			return false

		if saki.defeated:
			return false

		var delta := 1.0 / float(Engine.physics_ticks_per_second)
		elapsed += delta

		var weight := clampf(elapsed / duration, 0.0, 1.0)
		var desired_position := origin.lerp(destination, weight)
		var motion := desired_position - saki.global_position

		var collision := saki.move_and_collide(motion)

		if collision != null:
			return false

	return true


func _perform_dive() -> bool:
	var origin := saki.global_position

	# Commit to the selected horizontal target.
	# Keep Saki's original ground height.
	var destination := Vector2(
		target_position.x,
		start_position.y
	)

	var distance := origin.distance_to(destination)
	var duration := maxf(distance / dive_speed, 0.05)

	var elapsed := 0.0

	while elapsed < duration:
		if not is_inside_tree():
			return false

		await get_tree().physics_frame

		if not is_inside_tree():
			return false

		if saki.defeated:
			return false

		var delta := 1.0 / float(Engine.physics_ticks_per_second)
		elapsed += delta

		var weight := clampf(elapsed / duration, 0.0, 1.0)

		# Calculate the curved trajectory.
		var desired_position := origin.lerp(destination, weight)
		desired_position.y -= sin(weight * PI) * dive_arc_height

		var motion := desired_position - saki.global_position

		var collision := saki.move_and_collide(motion)

		_check_hit()

		if collision != null:
			# A collision with the floor counts as landing.
			if collision.get_normal().dot(Vector2.UP) > 0.7:
				return true

			return false

	return true


func _check_hit() -> void:
	if has_hit_player or hitbox == null:
		return

	for body in hitbox.get_overlapping_bodies():
		if body == player:
			has_hit_player = true

			var player_stats := player.get_node_or_null("Stats") as CharacterStats

			if player_stats != null:
				player_stats.take_damage(dive_damage)
				print("Saki's dive hit Mayumi!")

			return


func _finish_attack() -> void:
	_remove_landing_warning()

	if is_instance_valid(hitbox):
		hitbox.set_deferred("monitoring", false)

	if is_instance_valid(sprite):
		sprite.modulate = original_modulate

	if not saki.defeated:
		saki.velocity = Vector2.ZERO
		saki.set_physics_process(true)
		
func _show_landing_warning() -> void:
	if warning_scene == null:
		return

	landing_warning = warning_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(landing_warning)

	landing_warning.global_position = Vector2(
		target_position.x,
		start_position.y + warning_ground_offset
	)

	landing_warning.scale.x = impact_width / 16.0


func _impact_zone(zone_width: float, zone_height: float, zone_duration: float, zone_color: Color) -> void:
	var ground_y := start_position.y + warning_ground_offset

	var is_main_impact := is_equal_approx(zone_width, impact_width)
	Sfx.play("earth_impact", 0.0 if is_main_impact else -6.0, 1.0 if is_main_impact else 1.25)

	var zone := Area2D.new()
	zone.collision_layer = 0
	zone.monitorable = false

	var shape := RectangleShape2D.new()
	shape.size = Vector2(zone_width, zone_height)

	var collision := CollisionShape2D.new()
	collision.shape = shape
	zone.add_child(collision)

	var visual := Polygon2D.new()
	var half := Vector2(zone_width, zone_height) / 2.0
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	])
	visual.color = Color(zone_color, zone_color.a * zone_flash_opacity)
	zone.add_child(visual)

	var rocks: Array[RockPillar] = []
	var rock_count := maxi(int(zone_width / rock_spacing), 1)

	for i in range(rock_count):
		var x := -half.x + (float(i) + 0.5) * zone_width / float(rock_count)
		var from_center := absf(x) / maxf(half.x, 1.0)
		var height := zone_height * rock_height_scale * lerpf(1.0, 0.6, from_center) * randf_range(0.85, 1.1)
		var rock := RockPillar.create(height, from_center * rock_shockwave_time)
		rock.position = Vector2(x, half.y + 5.5)
		zone.add_child(rock)
		rocks.append(rock)

	get_tree().current_scene.add_child(zone)
	zone.global_position = Vector2(saki.global_position.x, ground_y - zone_height / 2.0)

	var tween := zone.create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, zone_duration)

	var zone_hit := false
	var elapsed := 0.0

	while elapsed < zone_duration:
		if not is_inside_tree():
			return

		await get_tree().physics_frame

		if not is_inside_tree():
			return
		elapsed += 1.0 / float(Engine.physics_ticks_per_second)

		if saki.defeated:
			break

		if zone_hit:
			continue

		for body in zone.get_overlapping_bodies():
			if body == player:
				zone_hit = true

				var player_stats := player.get_node_or_null("Stats") as CharacterStats

				if player_stats != null:
					player_stats.take_damage(impact_damage)
					print("Saki's dive impact hit Mayumi!")

	zone.set_deferred("monitoring", false)

	for rock in rocks:
		if is_instance_valid(rock):
			rock.retract()

	get_tree().create_timer(0.25, false).timeout.connect(zone.queue_free)


func _remove_landing_warning() -> void:
	if is_instance_valid(landing_warning):
		landing_warning.queue_free()

	landing_warning = null
