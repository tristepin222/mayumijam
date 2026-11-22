extends Node

@onready var player_stats: CharacterStats = $"../Mayumi/Stats"
@onready var boss_stats: CharacterStats = $"../Saki/Stats"
@onready var boss_ai: BossAI = $"../Saki/BossAi" if has_node("../Saki/BossAi") else null
@onready var mayumi: CharacterBody2D = $"../Mayumi"
@onready var saki: CharacterBody2D = $"../Saki"

@export var death_screen: CanvasLayer
@export var dialog_player: DialogPlayer

@export_group("Intro Cinematic")
@export var mayumi_entry_x: float = -140.0
@export var mayumi_stop_x: float = 0.0
@export var saki_stop_x: float = 110.0
@export var saki_entry_offset: Vector2 = Vector2(150.0, -120.0)
@export var saki_swoop_time: float = 0.8

@export_group("Ending")
@export var ending_delay: float = 1.2

@export_group("Death Fall")
@export var death_launch: Vector2 = Vector2(46.0, -30.0)
@export var death_fall_time: float = 0.7
@export var death_hold_time: float = 1.2
@export var death_lying_offset: float = 9.0
@export var arena_limits: Vector2 = Vector2(-140.0, 190.0)

var game_manager
var ground_y := 0.0
var saki_ground_y := 0.0
var death_fall_active := false
var death_skip_requested := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	player_stats.died.connect(_on_player_died)
	boss_stats.died.connect(_on_boss_defeated)

	if boss_ai != null and boss_ai.has_signal("phase_changed"):
		boss_ai.phase_changed.connect(_on_boss_phase_changed)

	ground_y = mayumi.global_position.y
	saki_ground_y = saki.global_position.y

	game_manager = get_node_or_null("/root/GameManager")

	if game_manager != null:
		game_manager.play_music(game_manager.get_fight_track())

	if dialog_player != null:
		dialog_player.cutscene_handler = _run_cutscene_event

	if game_manager != null and dialog_player != null:
		get_tree().paused = true
		_play_fight_dialog.call_deferred()


func _physics_process(_delta: float) -> void:
	if get_tree().paused or mayumi == null:
		return

	if mayumi.is_on_floor():
		ground_y = mayumi.global_position.y


func _play_fight_dialog() -> void:
	var diag: int = game_manager.get_fight_dialog()
	var context := {"keiki_outfit": "goddess"}

	if diag == DialogManager.situations.A1_INTRO:
		_begin_intro()
		await dialog_player.play_dialog(diag, context)

		var confrontation: int = game_manager.get_fight_dialog()
		await dialog_player.play_dialog(confrontation, context)
		_end_intro()
	else:
		await dialog_player.play_dialog(diag, context)

	get_tree().paused = false


func _begin_intro() -> void:
	_set_hud_visible(false)

	if boss_ai != null:
		boss_ai.process_mode = Node.PROCESS_MODE_DISABLED

	saki.process_mode = Node.PROCESS_MODE_DISABLED
	saki.visible = false

	mayumi.set("cinematic", true)
	mayumi.visible = false
	mayumi.global_position.x = mayumi_entry_x


func _end_intro() -> void:
	mayumi.set("cinematic", false)
	mayumi.set("cinematic_direction", 0.0)
	mayumi.visible = true

	saki.visible = true
	saki.process_mode = Node.PROCESS_MODE_INHERIT

	if boss_ai != null:
		boss_ai.process_mode = Node.PROCESS_MODE_INHERIT

	_set_hud_visible(true)


func _set_hud_visible(is_visible: bool) -> void:
	for hud_name in ["../HeartHUD", "../BossHealthBar"]:
		var hud := get_node_or_null(hud_name) as CanvasLayer

		if hud != null:
			hud.visible = is_visible


func _run_cutscene_event(event_name: String) -> void:
	match event_name:
		"mayumi_enter":
			await _mayumi_enter()
		"saki_enter":
			await _saki_enter()


func _mayumi_enter() -> void:
	var visual := mayumi.get_node_or_null("Mayumi") as CanvasItem

	mayumi.global_position.x = mayumi_entry_x
	mayumi.visible = true

	if visual != null:
		visual.modulate.a = 0.0
		create_tween().tween_property(visual, "modulate:a", 1.0, 0.35)

	get_tree().paused = false
	mayumi.set("cinematic_direction", 1.0)

	var elapsed := 0.0

	while mayumi.global_position.x < mayumi_stop_x and elapsed < 4.0:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()

	mayumi.set("cinematic_direction", 0.0)

	await get_tree().create_timer(0.4).timeout
	get_tree().paused = true


func _saki_enter() -> void:
	var landing := Vector2(saki_stop_x, saki_ground_y)

	saki.global_position = landing + saki_entry_offset
	saki.visible = true
	get_tree().paused = false

	var tween := create_tween()
	tween.tween_property(saki, "global_position", landing, saki_swoop_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

	_shake_camera(4.0, 0.25)
	saki.velocity = Vector2.ZERO
	saki.call("set_move_direction", 0.0)
	saki.process_mode = Node.PROCESS_MODE_INHERIT

	await get_tree().create_timer(0.5).timeout
	get_tree().paused = true


func _shake_camera(strength: float, duration: float) -> void:
	var camera := get_node_or_null("../Camera2D") as Camera2D

	if camera == null:
		return

	var tween := create_tween()
	var steps := 6

	for i in range(steps):
		var falloff := 1.0 - float(i) / steps
		tween.tween_property(camera, "offset", Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * falloff, duration / steps)

	tween.tween_property(camera, "offset", Vector2.ZERO, duration / steps)


func _on_boss_phase_changed(phase: int) -> void:
	if phase == BossAI.BossPhase.PHASE_2 and game_manager != null:
		game_manager.play_music("final_phase")

	if phase == BossAI.BossPhase.PHASE_2 and game_manager != null and dialog_player != null:
		var diag: int = game_manager.get_phase_2_dialog()
		if diag >= 0:
			get_tree().paused = true
			await dialog_player.play_dialog(diag, {"saki_damaged": true, "keiki_outfit": "goddess"})
			get_tree().paused = false


func _on_player_died() -> void:
	if game_manager != null and game_manager.victory:
		return

	print("Mayumi died!")

	if game_manager != null:
		game_manager.on_player_died()

	get_tree().paused = true
	await _play_death_fall()

	if dialog_player != null and game_manager != null:
		var defeat_diag: int = game_manager.get_defeat_dialog()
		if defeat_diag >= 0:
			var saki_hurt := boss_ai != null and boss_ai.current_phase == BossAI.BossPhase.PHASE_2
			await dialog_player.play_dialog(defeat_diag, {"mayumi_damaged": true, "saki_damaged": saki_hurt, "keiki_outfit": "goddess"})

	if death_screen != null and death_screen.has_method("show_screen"):
		death_screen.call("show_screen")
		return

	await get_tree().create_timer(2.0).timeout

	get_tree().reload_current_scene()


func _play_death_fall() -> void:
	if mayumi == null:
		return

	death_fall_active = true
	death_skip_requested = false

	var direction := 1.0

	if saki != null and absf(mayumi.global_position.x - saki.global_position.x) > 0.5:
		direction = signf(mayumi.global_position.x - saki.global_position.x)

	var start := mayumi.global_position
	var land_x := clampf(start.x + direction * death_launch.x, arena_limits.x, arena_limits.y)
	var land := Vector2(land_x, ground_y + death_lying_offset)
	var apex := Vector2(lerpf(start.x, land_x, 0.45), minf(start.y, ground_y) + death_launch.y)

	mayumi.modulate = Color(2.5, 2.5, 2.5, 1.0)
	create_tween().tween_property(mayumi, "modulate", Color.WHITE, 0.3)
	await _wait_or_skip(0.12)

	var fall := create_tween().set_parallel(true)
	fall.tween_method(func(t: float): mayumi.global_position = start.lerp(apex, t).lerp(apex.lerp(land, t), t), 0.0, 1.0, death_fall_time)
	fall.tween_property(mayumi, "rotation", direction * (PI * 0.5 + 0.35), death_fall_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await _finish_tween(fall)
	_shake_camera(3.0, 0.2)

	var bounce := create_tween()
	bounce.tween_property(mayumi, "global_position:y", land.y - 5.0, 0.12).set_ease(Tween.EASE_OUT)
	bounce.parallel().tween_property(mayumi, "rotation", direction * (PI * 0.5 - 0.12), 0.12)
	bounce.tween_property(mayumi, "global_position:y", land.y, 0.14).set_ease(Tween.EASE_IN)
	bounce.parallel().tween_property(mayumi, "rotation", direction * PI * 0.5, 0.14)
	await _finish_tween(bounce)

	await _wait_or_skip(death_hold_time)
	death_fall_active = false


func _finish_tween(tween: Tween) -> void:
	while tween.is_valid() and tween.is_running():
		if death_skip_requested:
			tween.custom_step(60.0)
			break

		await get_tree().process_frame


func _wait_or_skip(seconds: float) -> void:
	var elapsed := 0.0

	while elapsed < seconds and not death_skip_requested:
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _unhandled_input(event: InputEvent) -> void:
	if not death_fall_active:
		return

	if event.is_action_pressed("sword") or event.is_action_pressed("update_dialog") or event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		death_skip_requested = true
		get_viewport().set_input_as_handled()


func _on_boss_defeated() -> void:
	print("Saki defeated")

	if game_manager == null:
		return

	game_manager.on_boss_defeated()
	mayumi.set("is_invincible", true)

	await get_tree().create_timer(ending_delay, false).timeout

	if dialog_player != null:
		game_manager.play_music("final_cutscene")
		get_tree().paused = true
		_set_hud_visible(false)
		await dialog_player.play_dialog(game_manager.get_ending_dialog(), {"saki_damaged": true, "keiki_outfit": "goddess"})

	game_manager.show_end_screen()


func restart_combat() -> void:
	player_stats.reset()
	boss_stats.reset()
