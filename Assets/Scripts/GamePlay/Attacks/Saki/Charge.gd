
extends BossAttack

@export_group("Attack")
@export var preparation_time: float = 0.5
@export var recovery_time: float = 0.7
@export var damage: int = 20

@export_group("Charge Movement")
@export var charge_speed: float = 700.0
@export var max_charge_distance: float = 500.0
@export_range(1, 6) var charge_count: int = 3
@export var between_charges_time: float = 0.45

@export_group("Telegraph")
@export var flash_color: Color = Color(2.0, 0.6, 0.6)

@export_group("Visual Assets")
@export var charge_effect_scene: PackedScene

var charge_effect: Node2D


func execute() -> void:
	if saki == null or player == null:
		push_warning("Charge: Missing Saki or player reference.")
		return

	saki.set_move_direction(0.0)

	print("Saki is preparing to charge!")

	var landed: bool = await _force_land()

	if not landed or saki.defeated:
		return

	saki.velocity = Vector2.ZERO
	saki.set_physics_process(false)

	for i in range(charge_count):
		if saki.defeated:
			break

		var wait_time := preparation_time if i == 0 else between_charges_time
		await _flash(wait_time)

		if saki.defeated:
			break

		var direction := signf(
			player.global_position.x - saki.global_position.x
		)

		if direction == 0.0:
			direction = 1.0

		print("Saki charges! (", i + 1, "/", charge_count, ")")

		_spawn_charge_effect(direction)

		await _perform_charge(direction)

		if is_instance_valid(charge_effect):
			charge_effect.queue_free()

		charge_effect = null

	if saki.defeated:
		_finish_attack()
		return

	print("Saki is recovering!")

	if not is_inside_tree():
		return

	await get_tree().create_timer(recovery_time).timeout

	if not is_inside_tree():
		return

	_finish_attack()


func _flash(duration: float) -> void:
	var sprite := saki.get_node_or_null("Sprite2D") as CanvasItem

	if sprite == null or duration <= 0.0:
		if not is_inside_tree():
			return

		await get_tree().create_timer(maxf(duration, 0.0)).timeout

		if not is_inside_tree():
			return
		return

	var base_color := sprite.modulate

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", flash_color, duration * 0.5)
	tween.tween_property(sprite, "modulate", base_color, duration * 0.5)

	await tween.finished


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


func _perform_charge(direction: float) -> void:
	var travelled_distance := 0.0

	while travelled_distance < max_charge_distance:
		if not is_inside_tree():
			return

		await get_tree().physics_frame

		if not is_inside_tree():
			return

		if saki.defeated:
			return

		var delta := 1.0 / float(Engine.physics_ticks_per_second)

		var movement := Vector2(
			direction * charge_speed * delta,
			0.0
		)

		var collision := saki.move_and_collide(movement)

		travelled_distance += movement.length()

		if collision != null:
			var collider := collision.get_collider()

			if collider == player:
				_damage_player()
				print("Saki hit Mayumi with Charge!")
			else:
				print("Saki's charge was blocked!")

			return


func _damage_player() -> void:
	var player_stats := player.get_node_or_null("Stats") as CharacterStats

	if player_stats != null:
		player_stats.take_damage(damage, CharacterStats.DamagePhase.PHASE_2)


func _spawn_charge_effect(direction: float) -> void:
	if charge_effect_scene == null:
		return

	charge_effect = charge_effect_scene.instantiate() as Node2D

	if charge_effect == null:
		push_warning("Charge: Effect scene root must be Node2D.")
		return

	saki.add_child(charge_effect)
	charge_effect.position = Vector2.ZERO

	# Flip the effect according to the charge direction.
	charge_effect.scale.x = absf(charge_effect.scale.x) * direction


func _finish_attack() -> void:
	if is_instance_valid(charge_effect):
		charge_effect.queue_free()

	charge_effect = null

	if not saki.defeated:
		saki.velocity = Vector2.ZERO
		saki.set_physics_process(true)

	print("Charge finished!")
