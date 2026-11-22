extends Node

@onready var player_stats: CharacterStats = $"../Mayumi/Stats"
@onready var boss_stats: CharacterStats = $"../Saki/Stats"

@export var death_screen: CanvasLayer
@export var dialog_player: DialogPlayer

var game_manager


func _ready() -> void:
	player_stats.died.connect(_on_player_died)
	boss_stats.died.connect(_on_boss_defeated)

	game_manager = get_node_or_null("/root/GameManager")

	if game_manager != null:
		game_manager.play_music(game_manager.get_fight_track())

		var boss_ai := get_node_or_null("../Saki/BossAi")

		if boss_ai != null and boss_ai.has_signal("phase_changed"):
			boss_ai.connect("phase_changed", _on_boss_phase_changed)

	if game_manager != null and dialog_player != null:
		get_tree().paused = true
		_play_fight_dialog.call_deferred()


func _play_fight_dialog() -> void:
	await dialog_player.play_dialog(game_manager.get_fight_dialog())
	get_tree().paused = false


func _on_boss_phase_changed(phase: int) -> void:
	if game_manager != null and phase > 0:
		game_manager.play_music("final_phase")


func _on_player_died() -> void:
	print("Mayumi died!")

	if game_manager != null:
		game_manager.on_player_died()

	if death_screen != null and death_screen.has_method("show_screen"):
		death_screen.call("show_screen")
		return

	await get_tree().create_timer(2.0).timeout

	get_tree().reload_current_scene()


func _on_boss_defeated() -> void:
	print("Saki defeated")

	if game_manager != null:
		game_manager.on_boss_defeated()


func restart_combat() -> void:
	player_stats.reset()
	boss_stats.reset()
