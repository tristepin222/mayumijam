extends PlayerAbility

@export_group("Charge")
@export var charge_speed: float = 900.0
@export var charge_duration: float = 0.35
@export var cooldown: float = 2.0

@export_group("Combat")
@export var damage: int = 25

var can_charge := true
var is_charging := false
var has_hit_enemy := false


func _ready() -> void:
	ability_id = "haniwa_charge"


func activate() -> void:
	if not can_activate():
		return

	if not can_charge or is_charging:
		return

	var saki := get_tree().get_first_node_in_group("enemies") as SakiController

	if saki == null:
		return

	ability_manager.use_ability(ability_id)

	can_charge = false
	is_charging = true
	has_hit_enemy = false

	_perform_charge(saki)


func _perform_charge(saki: SakiController) -> void:
	var direction: float = mayumi.facing_direction
	var elapsed := 0.0

	# Mayumi cannot be damaged during the charge.
	mayumi.is_invincible = true

	while elapsed < charge_duration:
		if not is_instance_valid(mayumi):
			break

		var delta := get_physics_process_delta_time()

		mayumi.velocity = Vector2(
			direction * charge_speed,
			0.0
		)

		mayumi.move_and_slide()

		if not has_hit_enemy and is_instance_valid(saki):
			if _is_touching_saki(saki):
				_damage_saki(saki)

		elapsed += delta
		await get_tree().physics_frame

	if is_instance_valid(mayumi):
		mayumi.is_invincible = false
		mayumi.velocity.x = 0.0

	is_charging = false

	await get_tree().create_timer(cooldown).timeout
	can_charge = true


func _is_touching_saki(saki: SakiController) -> bool:
	return mayumi.get_node("CollisionShape2D").shape != null \
		and mayumi.global_position.distance_to(saki.global_position) < 80.0


func _damage_saki(saki: SakiController) -> void:
	has_hit_enemy = true

	var enemy_stats := saki.get_node_or_null("Stats") as CharacterStats

	if enemy_stats != null:
		enemy_stats.take_damage(damage)
		print("Haniwa Charge hit Saki!")
