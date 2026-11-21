extends PlayerAbility

var dash_ability: Node


func _ready() -> void:
	ability_id = AbilityIDs.Ability.CLAY_GRAZE


func setup(player: CharacterBody2D, manager: Node) -> void:
	super.setup(player, manager)

	dash_ability = mayumi.get_node("Abilities/Dash")

	dash_ability.dash_started.connect(_on_dash_started)
	dash_ability.dash_finished.connect(_on_dash_finished)


func _on_dash_started() -> void:
	if can_activate():
		mayumi.is_grazing_projectiles = true


func _on_dash_finished() -> void:
	mayumi.is_grazing_projectiles = false
