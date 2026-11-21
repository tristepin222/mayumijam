
extends BossAttack

@export_group("Attack")
@export var preparation_time: float = 0.5
@export var recovery_time: float = 0.7
@export var damage: int = 20

@export_group("Charge Movement")
@export var charge_speed: float = 700.0
@export var max_charge_distance: float = 500.0

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

	await get_tree().create_timer(preparation_time).timeout

	if saki.defeated:
		_finish_attack()
		return

	# Determine charge direction.
	var direction := signf(
		player.global_position.x - saki.global_position.x
	)

	if direction == 0.0:
		direction = 1.0

	print("Saki charges!")

	_spawn_charge_effect(direction)

	await _perform_charge(direction)

	if saki.defeated:
		_finish_attack()
		return

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


func _perform_charge(direction: float) -> void:
	var travelled_distance := 0.0

	while travelled_distance < max_charge_distance:
		await get_tree().physics_frame

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
		player_stats.take_damage(damage)


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
