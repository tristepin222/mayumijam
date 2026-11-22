extends Area2D

@export var damage: int = 1
@export var pass_through_player: bool = true

var body: PhysicsBody2D
var player: CharacterBody2D


func _ready() -> void:
	body = get_parent() as PhysicsBody2D
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if body == null or player == null:
		push_warning("ContactDamage: Needs a physics body parent and a player in the 'player' group.")
		set_physics_process(false)
		return

	if pass_through_player:
		body.add_collision_exception_with(player)
		player.add_collision_exception_with(body)


func _physics_process(_delta: float) -> void:
	if damage <= 0:
		return

	if body.get("defeated"):
		return

	for overlapping in get_overlapping_bodies():
		if overlapping == player:
			var player_stats := player.get_node_or_null("Stats") as CharacterStats

			if player_stats != null:
				player_stats.take_damage(damage, _get_damage_phase())

			return


func _get_damage_phase() -> CharacterStats.DamagePhase:
	var boss_ai := body.get_node_or_null("BossAi")

	if boss_ai != null and int(boss_ai.get("current_phase")) > 0:
		return CharacterStats.DamagePhase.PHASE_2

	return CharacterStats.DamagePhase.PHASE_1
