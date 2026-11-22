
extends PlayerAbility

@export_group("Haniwa")
@export var turret_scene: PackedScene
@export var summon_offset: Vector2 = Vector2(45.0, 0.0)

@export_group("Cooldown")
@export var cooldown: float = 4.0

var can_summon := true


func _ready() -> void:
	ability_id = AbilityIDs.Ability.CERAMIC_BARRAGE


func activate() -> void:
	if not can_activate():
		return

	if not can_summon:
		return

	if turret_scene == null:
		push_warning("CeramicBarrage: Assign a Haniwa turret scene.")
		return

	var saki := get_tree().get_first_node_in_group("enemies") as SakiController

	if saki == null:
		return

	ability_manager.use_ability(ability_id)
	can_summon = false

	var turret := turret_scene.instantiate() as Node2D

	if turret == null:
		can_summon = true
		return

	get_tree().current_scene.add_child(turret)

	turret.global_position = mayumi.global_position + Vector2(
		summon_offset.x * mayumi.facing_direction,
		summon_offset.y
	)

	turret.call("setup", saki)

	await get_tree().create_timer(cooldown).timeout
	can_summon = true
