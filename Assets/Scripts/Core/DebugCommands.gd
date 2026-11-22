extends Node

const SAKI_ATTACKS = [
	[KEY_1, "counter", "Counter"],
	[KEY_2, "dive", "Dive"],
	[KEY_3, "normal_danmaku", "Normal Danmaku"],
	[KEY_4, "comeback_danmaku", "Comeback Danmaku"],
	[KEY_5, "tectonic_push", "Tectonic Push"],
	[KEY_6, "charge", "Charge"],
	[KEY_7, "unleash", "Unleash"],
	[KEY_8, "danmaku_rain", "Danmaku Rain"],
]

const KEY_HELP = KEY_F1
const KEY_GOD = KEY_G
const KEY_HEAL = KEY_H
const KEY_FREEZE = KEY_B
const KEY_PHASE_2 = KEY_N
const KEY_UNLOCK = KEY_U

var god_mode := false
var ai_frozen := false

var layer: CanvasLayer
var help_panel: PanelContainer
var status_label: Label
var toast_label: Label
var toast_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	_refresh_status()


func _build_overlay() -> void:
	layer = CanvasLayer.new()
	layer.layer = 90
	add_child(layer)

	status_label = _make_label(16)
	status_label.position = Vector2(12.0, 0.0)
	status_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	status_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	status_label.offset_top = -30.0
	status_label.offset_bottom = -8.0
	status_label.offset_left = 12.0
	layer.add_child(status_label)

	toast_label = _make_label(22)
	toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_label.offset_top = -80.0
	toast_label.offset_bottom = -50.0
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	layer.add_child(toast_label)

	help_panel = PanelContainer.new()
	help_panel.position = Vector2(12.0, 120.0)
	help_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12.0)
	help_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(help_panel)

	var lines: Array[String] = ["TEST COMMANDS", ""]

	for entry in SAKI_ATTACKS:
		lines.append("%s   Saki: %s" % [OS.get_keycode_string(entry[0]), entry[2]])

	lines.append("")
	lines.append("G   God mode")
	lines.append("H   Refill hearts")
	lines.append("B   Freeze Saki's AI")
	lines.append("N   Skip to phase 2")
	lines.append("U   Unlock all abilities")
	lines.append("F1  Hide this list")

	var help_label := _make_label(16)
	help_label.text = "\n".join(lines)
	help_panel.add_child(help_label)


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey

	if key_event == null or not key_event.pressed or key_event.echo:
		return

	var code := key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode

	match code:
		KEY_HELP:
			help_panel.visible = not help_panel.visible
			_refresh_status()
		KEY_GOD:
			god_mode = not god_mode
			if not god_mode:
				var mayumi := _get_mayumi()
				if mayumi != null:
					mayumi.set("is_invincible", false)
			_toast("God mode " + ("ON" if god_mode else "OFF"))
		KEY_HEAL:
			_heal()
		KEY_FREEZE:
			ai_frozen = not ai_frozen
			var boss_ai := _get_boss_ai()
			if boss_ai != null:
				boss_ai.planned_attack = ""
				if not ai_frozen and not boss_ai.is_attacking:
					boss_ai.attack_ready = true
			_toast("Saki AI " + ("FROZEN" if ai_frozen else "ON"))
		KEY_PHASE_2:
			_skip_to_phase_2()
		KEY_UNLOCK:
			_unlock_all()
		_:
			for entry in SAKI_ATTACKS:
				if entry[0] == code:
					_force_attack(entry[1], entry[2])
					break
			return

	_refresh_status()


func _process(delta: float) -> void:
	_apply_god_mode()

	if toast_timer > 0.0:
		toast_timer -= delta

		if toast_timer <= 0.0:
			toast_label.text = ""


func _physics_process(_delta: float) -> void:
	_apply_god_mode()

	if ai_frozen:
		var boss_ai := _get_boss_ai()

		if boss_ai != null:
			boss_ai.attack_ready = false
			boss_ai.planned_attack = ""


func _apply_god_mode() -> void:
	if not god_mode:
		return

	var mayumi := _get_mayumi()

	if mayumi != null:
		mayumi.set("is_invincible", true)


func _force_attack(attack_id: String, display_name: String) -> void:
	var boss_ai := _get_boss_ai()
	var saki := _get_saki()

	if boss_ai == null or saki == null or saki.defeated:
		_toast("No Saki here")
		return

	if get_tree().paused:
		_toast("Game is paused")
		return

	var attack_manager = boss_ai.attack_manager

	if attack_manager == null or not attack_manager.attacks.has(attack_id):
		_toast("Saki has no %s" % display_name)
		return

	if boss_ai.is_attacking or attack_manager.is_executing:
		_toast("Saki is busy, try again")
		return

	_toast("Saki: " + display_name)

	boss_ai.planned_attack = ""
	boss_ai.is_attacking = true
	boss_ai.attack_ready = false
	saki.set_move_direction(0.0)

	await boss_ai._telegraph()

	if not _is_alive(boss_ai) or saki.defeated:
		return

	await attack_manager.execute_attack(attack_id)

	if not _is_alive(boss_ai):
		return

	boss_ai.is_attacking = false

	await get_tree().create_timer(boss_ai.attack_cooldown, false).timeout

	if _is_alive(boss_ai) and not ai_frozen and not boss_ai.is_attacking:
		boss_ai.attack_ready = true


func _heal() -> void:
	var mayumi := _get_mayumi()

	if mayumi == null:
		return

	var stats := mayumi.get_node_or_null("Stats") as CharacterStats

	if stats != null:
		stats.reset()
		_toast("Hearts refilled")


func _skip_to_phase_2() -> void:
	var boss_ai := _get_boss_ai()
	var saki := _get_saki()

	if boss_ai == null or saki == null:
		_toast("No Saki here")
		return

	if boss_ai.current_phase != 0:
		_toast("Already in phase 2")
		return

	var stats := saki.get_node_or_null("Stats") as CharacterStats

	if stats == null:
		return

	var target := int(floor(stats.max_health * boss_ai.phase_2_health_threshold))
	stats.health = mini(stats.health, target)
	stats.health_changed.emit(stats.health, stats.max_health)
	_toast("Skipped to phase 2")


func _unlock_all() -> void:
	var scene := get_tree().current_scene

	if scene == null:
		return

	var ability_manager := scene.get_node_or_null("AbilityManager")

	if ability_manager == null:
		_toast("No Mayumi here")
		return

	for id in AbilityIDs.Ability.values():
		ability_manager.unlock_ability(id)
		ability_manager.equip_ability(id)

	_toast("All abilities unlocked for this fight")


func _get_mayumi() -> Node:
	return get_tree().get_first_node_in_group("player")


func _get_saki() -> Node:
	var scene := get_tree().current_scene

	if scene == null:
		return null

	return scene.get_node_or_null("Saki")


func _get_boss_ai() -> Node:
	var saki := _get_saki()

	if saki == null:
		return null

	return saki.get_node_or_null("BossAi")


func _is_alive(node: Node) -> bool:
	return is_instance_valid(node) and node.is_inside_tree()


func _toast(text: String) -> void:
	toast_label.text = text
	toast_timer = 1.5


func _refresh_status() -> void:
	var parts: Array[String] = []

	if god_mode:
		parts.append("GOD MODE")

	if ai_frozen:
		parts.append("SAKI AI FROZEN")

	if parts.is_empty():
		status_label.text = "" if help_panel.visible else "F1: Test commands"
	else:
		status_label.text = "  |  ".join(parts) + "    (F1: Test commands)"
