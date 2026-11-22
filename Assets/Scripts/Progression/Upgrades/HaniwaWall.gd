
extends Area2D

@export_group("Wall")
@export var duration: float = 0.6
@export var damage: int = 15

var mayumi: CharacterBody2D
var saki: SakiController


func setup(player: CharacterBody2D, enemy: SakiController) -> void:
	mayumi = player
	saki = enemy


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	await get_tree().create_timer(duration).timeout

	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body != saki:
		return

	var enemy_stats := saki.get_node_or_null("Stats") as CharacterStats

	if enemy_stats != null:
		enemy_stats.take_damage(damage)


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("reflect"):
		area.reflect(saki)
