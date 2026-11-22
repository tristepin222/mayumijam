
extends Area2D

@export_group("Wall")
@export var duration: float = 0.6
@export var damage: int = 15

@export_group("Visual")
@export var pop_time: float = 0.12

var mayumi: CharacterBody2D
var saki: SakiController


func setup(player: CharacterBody2D, enemy: SakiController) -> void:
	mayumi = player
	saki = enemy


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	var sprite := get_node_or_null("HaniwaSprite") as Node2D

	if sprite == null:
		await get_tree().create_timer(duration).timeout
		queue_free()
		return

	var full_scale := sprite.scale
	sprite.scale = Vector2(full_scale.x * 1.3, 0.0)
	Sfx.play("land", 4.0, 0.8)
	create_tween().tween_property(sprite, "scale", full_scale, pop_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(maxf(duration - pop_time, 0.0)).timeout

	var sink := create_tween()
	sink.tween_property(sprite, "scale", Vector2(full_scale.x * 1.2, 0.0), pop_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await sink.finished

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
		Sfx.play("sword_hit", -2.0, 1.6)
