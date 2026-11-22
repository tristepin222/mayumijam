extends PlayerAbility

signal dash_started
signal dash_finished

@export_group("Dash")
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

@export_group("Visual Assets")
@export var dash_effect_scene: PackedScene

var is_dashing := false
var can_dash := true
var dash_effect: Node2D


func _ready() -> void:
	ability_id = AbilityIDs.Ability.DASH


func activate() -> void:
	if not can_activate():
		return

	if not can_dash or is_dashing:
		return

	ability_manager.use_ability(ability_id)

	is_dashing = true
	can_dash = false
	Sfx.play("dash")

	dash_started.emit()

	_spawn_effect()
	_perform_dash()


func _perform_dash() -> void:
	var direction: float = mayumi.facing_direction
	var elapsed := 0.0

	while elapsed < dash_duration:
		if not is_instance_valid(mayumi):
			break

		var delta := get_physics_process_delta_time()

		mayumi.velocity = Vector2(
			direction * dash_speed,
			0.0
		)

		mayumi.move_and_slide()

		elapsed += delta

		await get_tree().physics_frame

	is_dashing = false
	dash_finished.emit()

	if is_instance_valid(dash_effect):
		dash_effect.queue_free()

	dash_effect = null

	if is_instance_valid(mayumi):
		mayumi.velocity.x = 0.0

	await get_tree().create_timer(dash_cooldown).timeout

	can_dash = true


func _spawn_effect() -> void:
	if dash_effect_scene == null:
		return

	dash_effect = dash_effect_scene.instantiate() as Node2D

	if dash_effect == null:
		push_warning("Dash: Effect root must be Node2D.")
		return

	mayumi.add_child(dash_effect)
	dash_effect.position = Vector2.ZERO
	dash_effect.scale.x = absf(dash_effect.scale.x) * mayumi.facing_direction
