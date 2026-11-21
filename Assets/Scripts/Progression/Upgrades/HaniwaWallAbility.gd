
extends PlayerAbility

@export_group("Wall")
@export var wall_scene: PackedScene
@export var wall_offset: Vector2 = Vector2(45.0, 0.0)

@export_group("Cooldown")
@export var cooldown: float = 2.0

var can_use := true


func _ready() -> void:
	ability_id = AbilityIDs.Ability.HANIWA_WALL


func activate() -> void:
	if not can_activate() or not can_use:
		return

	if wall_scene == null:
		push_warning("HaniwaWall: Assign a wall scene.")
		return

	var saki := get_tree().get_first_node_in_group("enemies") as SakiController

	if saki == null:
		return

	ability_manager.use_ability(ability_id)
	can_use = false

	var wall := wall_scene.instantiate() as Area2D

	if wall == null:
		push_warning("HaniwaWall: Scene root must be Area2D.")
		can_use = true
		return

	get_tree().current_scene.add_child(wall)

	wall.global_position = mayumi.global_position + Vector2(
		absf(wall_offset.x) * mayumi.facing_direction,
		wall_offset.y
	)

	wall.call("setup", mayumi, saki)

	await get_tree().create_timer(cooldown).timeout

	can_use = true
