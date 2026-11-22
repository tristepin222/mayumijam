extends Node

@onready var player_stats: CharacterStats = $"../Mayumi/Stats"
@onready var boss_stats: CharacterStats = $"../Saki/Stats"
@onready var boss_ai: BossAI = $"../Saki/BossAi" if has_node("../Saki/BossAi") else null

@export var death_screen: CanvasLayer
@export var dialog_player: DialogPlayer

var game_manager


func _ready() -> void:
	player_stats.died.connect(_on_player_died)
	boss_stats.died.connect(_on_boss_defeated)

	if boss_ai != null and boss_ai.has_signal("phase_changed"):
		boss_ai.phase_changed.connect(_on_boss_phase_changed)

	game_manager = get_node_or_null("/root/GameManager")

	if game_manager != null and dialog_player != null:
		get_tree().paused = true
		_play_fight_dialog.call_deferred()


func _play_fight_dialog() -> void:
	var diag: int = game_manager.get_fight_dialog()
	await dialog_player.play_dialog(diag)

	# If intro narrative played, immediately follow with the first fight confrontation
	if diag == DialogManager.situations.A1_INTRO:
		var confrontation: int = game_manager.get_fight_dialog()
		await dialog_player.play_dialog(confrontation)

	get_tree().paused = false


func _on_boss_phase_changed(phase: int) -> void:
	if phase == BossAI.BossPhase.PHASE_2 and game_manager != null and dialog_player != null:
		var diag: int = game_manager.get_phase_2_dialog()
		if diag >= 0:
			get_tree().paused = true
			await dialog_player.play_dialog(diag)
			get_tree().paused = false


func _on_player_died() -> void:
	print("Mayumi died!")

	if game_manager != null:
		game_manager.on_player_died()

	if dialog_player != null and game_manager != null:
		var defeat_diag: int = game_manager.get_defeat_dialog()
		if defeat_diag >= 0:
			get_tree().paused = true
			await dialog_player.play_dialog(defeat_diag)
			get_tree().paused = false

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
