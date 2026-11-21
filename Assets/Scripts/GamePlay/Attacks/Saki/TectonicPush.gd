
extends BossAttack

@export_group("Visual Assets")
@export var warning_scene: PackedScene
@export var fire_pillar_scene: PackedScene

@export_group("Attack")
@export var preparation_time: float = 0.7
@export var recovery_time: float = 0.8
@export var damage: int = 20

@export_group("Targeting")
@export var max_target_distance: float = 500.0
@export var ground_offset: float = 32.0

@export_group("Repeated Attack")
@export var repeated_kicks: int = 4
@export var kick_interval: float = 0.45
@export_range(0.0, 1.0) var repeated_attack_chance: float = 0.4

@export_group("Pillars")
@export_range(1, 7) var pillar_count: int = 3
@export var pillar_spacing: float = 48.0
@export var arena_left_x: float = -138.0
@export var arena_right_x: float = 186.0

var is_executing := false


func execute() -> void:
	if saki == null or player == null:
		push_warning("Tectonic Push: Missing references.")
		return

	if warning_scene == null or fire_pillar_scene == null:
		push_warning("Tectonic Push: Assign both visual scenes in the Inspector.")
		return

	if is_executing:
		return

	is_executing = true
	saki.set_move_direction(0.0)

	var landed: bool = await _force_land()

	if not landed or saki.defeated:
		is_executing = false
		return

	saki.velocity = Vector2.ZERO
	saki.set_physics_process(false)

	print("Saki prepares Tectonic Push!")

	if randf() < repeated_attack_chance:
		await _perform_repeated_push()
	else:
		await _perform_single_push()

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


func _perform_single_push() -> void:
	var target_x := _get_target_x()

	await _perform_pillars(_get_pillar_xs(target_x, 0))


func _perform_repeated_push() -> void:
	for i in range(repeated_kicks):
		if saki.defeated:
			return

		print("Saki kicks the ground: ", i + 1)

		var target_x := _get_target_x()

		await _perform_pillars(_get_pillar_xs(target_x, i))

		if saki.defeated:
			return

		if i < repeated_kicks - 1:
			await get_tree().create_timer(kick_interval).timeout


func _get_target_x() -> float:
	var difference := player.global_position.x - saki.global_position.x

	difference = clampf(
		difference,
		-max_target_distance,
		max_target_distance
	)

	return saki.global_position.x + difference


func _get_pillar_xs(center_x: float, kick_index: int) -> Array[float]:
	var xs: Array[float] = []

	var shift := pillar_spacing * 0.5 if kick_index % 2 == 1 else 0.0
	var first := center_x + shift - pillar_spacing * float(pillar_count - 1) / 2.0

	for i in range(pillar_count):
		var x := first + pillar_spacing * float(i)

		if x >= arena_left_x and x <= arena_right_x:
			xs.append(x)

	return xs


func _perform_pillars(xs: Array[float]) -> void:
	var world := get_tree().current_scene
	var ground_y := saki.global_position.y + ground_offset

	var warnings: Array[Node] = []

	for x in xs:
		var warning := warning_scene.instantiate()
		world.add_child(warning)

		if warning is Node2D:
			warning.global_position = Vector2(x, ground_y)

		warnings.append(warning)

	# Give Mayumi time to react.
	await get_tree().create_timer(preparation_time).timeout

	for warning in warnings:
		if is_instance_valid(warning):
			warning.queue_free()

	if saki.defeated:
		return

	var pillars: Array[Node] = []

	for x in xs:
		var pillar := fire_pillar_scene.instantiate()
		world.add_child(pillar)

		if pillar is Node2D:
			pillar.global_position = Vector2(x, ground_y)

		if pillar is Area2D:
			pillar.body_entered.connect(
				_on_pillar_body_entered.bind(pillar)
			)

		pillars.append(pillar)

	await get_tree().create_timer(0.65).timeout

	for pillar in pillars:
		if is_instance_valid(pillar):
			pillar.queue_free()


func _on_pillar_body_entered(body: Node2D, pillar: Area2D) -> void:
	if body != player:
		return

	if not is_instance_valid(pillar):
		return

	if pillar.get_meta("already_hit", false):
		return

	pillar.set_meta("already_hit", true)

	var player_stats := player.get_node_or_null("Stats") as CharacterStats

	if player_stats != null:
		player_stats.take_damage(damage)
		print("Mayumi was hit by Tectonic Push!")


func _finish_attack() -> void:
	is_executing = false

	if not saki.defeated:
		saki.velocity = Vector2.ZERO
		saki.set_physics_process(true)

	print("Tectonic Push finished!")
