
extends PlayerAbility

@export_group("Attack")
@export var damage: int = 10
@export var attack_duration: float = 0.2
@export var cooldown: float = 0.4

@export_group("Hitbox")
@export var sword_hitbox: Area2D
@export var hitbox_offset: Vector2 = Vector2(35.0, 0.0)

@export_group("Visual Assets")
@export var slash_effect_scene: PackedScene

var can_attack := true
var is_attacking := false
var slash_effect: Node2D

var shattering_blow: PlayerAbility

func _ready() -> void:
	ability_id = "sword_attack"
	shattering_blow = get_node_or_null("../ShatteringBlow") as PlayerAbility
	
	if sword_hitbox == null:
		push_warning("SwordAttack: Assign SwordHitbox in the Inspector.")
		return

	sword_hitbox.monitoring = false


func activate() -> void:
	if not can_activate():
		return

	if not can_attack or is_attacking:
		return

	if sword_hitbox == null:
		return

	ability_manager.use_ability(ability_id)

	can_attack = false
	is_attacking = true

	mayumi.physical_attack_started.emit()

	_position_hitbox()
	_spawn_slash_effect()

	sword_hitbox.monitoring = true

	await get_tree().physics_frame
	await get_tree().physics_frame

	
	_damage_enemies()

	await get_tree().create_timer(attack_duration).timeout

	sword_hitbox.monitoring = false
	is_attacking = false

	if is_instance_valid(slash_effect):
		slash_effect.queue_free()

	slash_effect = null

	await get_tree().create_timer(cooldown).timeout
	can_attack = true


func _position_hitbox() -> void:
	var direction: float = mayumi.facing_direction

	sword_hitbox.position = Vector2(
		absf(hitbox_offset.x) * direction,
		hitbox_offset.y
	)


func _damage_enemies() -> void:
	var bodies := sword_hitbox.get_overlapping_bodies()

	for body in bodies:
		if not body.is_in_group("enemies"):
			continue

		var enemy_stats := body.get_node_or_null("Stats") as CharacterStats

		if enemy_stats == null:
			continue

		var saki := body as SakiController

		if saki == null:
			continue

		# Saki is cracked: consume the crack.
		if enemy_stats != null:
			enemy_stats.take_damage(damage)

			if shattering_blow != null:
				shattering_blow.register_sword_hit(body, enemy_stats)

func _spawn_slash_effect() -> void:
	if slash_effect_scene == null:
		return

	slash_effect = slash_effect_scene.instantiate() as Node2D

	if slash_effect == null:
		push_warning("SwordAttack: Effect root must be Node2D.")
		return

	mayumi.add_child(slash_effect)

	var direction: float = mayumi.facing_direction

	# Position the slash on the side Mayumi is facing.
	slash_effect.position = Vector2(
		absf(hitbox_offset.x) * direction,
		hitbox_offset.y
	)

	# Mirror the slash using the same logic as Dash.
	slash_effect.scale.x = absf(slash_effect.scale.x) * direction
