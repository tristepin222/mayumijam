extends Node

@onready var player_stats: CharacterStats = $"../Mayumi/Stats"
@onready var boss_stats: CharacterStats = $"../Saki/Stats"


func _ready() -> void:
	player_stats.died.connect(_on_player_died)
	boss_stats.died.connect(_on_boss_defeated)


func _on_player_died() -> void:
	print("Mayumi died")


func _on_boss_defeated() -> void:
	print("Saki defeated")


func restart_combat() -> void:
	player_stats.reset()
	boss_stats.reset()
