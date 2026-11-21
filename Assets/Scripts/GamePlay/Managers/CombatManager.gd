extends Node

@onready var player_stats: CharacterStats = $"../Mayumi/Stats"
@onready var boss_stats: CharacterStats = $"../Saki/Stats"

@export var death_screen: CanvasLayer


func _ready() -> void:
	player_stats.died.connect(_on_player_died)
	boss_stats.died.connect(_on_boss_defeated)


func _on_player_died() -> void:
	print("Mayumi died!")

	if death_screen != null and death_screen.has_method("show_screen"):
		death_screen.call("show_screen")
		return

	await get_tree().create_timer(2.0).timeout

	get_tree().reload_current_scene()


func _on_boss_defeated() -> void:
	print("Saki defeated")


func restart_combat() -> void:
	player_stats.reset()
	boss_stats.reset()
