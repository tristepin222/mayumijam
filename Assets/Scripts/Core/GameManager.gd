extends Node
class_name GameplayManager

signal upgrade_taken(upgrade: UpgradeStruct)

const FIGHT_SCENE := "res://Assets/Scenes/MainGame.tscn"
const KILN_SCENE := "res://Assets/Scenes/Kiln.tscn"
const MENU_SCENE := "res://Assets/Scenes/MainMenu.tscn"

const BASE_HEARTS := 1
const MAX_HEALTH_TIER := 6
const MAX_DAMAGE_TIER := 6
const DAMAGE_PER_TIER := 0.2
const UPGRADES_PER_STORY := 3

const FIGHT_THEME_1_LAST_ATTEMPT := 6
const FIGHT_THEME_2_LAST_ATTEMPT := 10
const SHOP_COLD_LAST_DEATH := 6
const SHOP_MUSIC_START := 20.0

const BASE_ABILITIES := ["dash", "sword_attack"]

const ABILITY_POOL := [
	{"id": "clay_graze", "name": "Clay Graze", "description": "Your dash passes through Saki's danmaku."},
	{"id": "haniwa_leap", "name": "Haniwa Leap", "description": "Press X in the air to double jump."},
	{"id": "arrow_volley", "name": "Arrow Volley", "description": "Unlocks danmaku (A). Tap for one arrow, hold to charge a spread of 5."},
	{"id": "shattering_blow", "name": "Shattering Blow", "description": "Every 5th sword hit cracks Saki. Your next hit deals bonus damage and staggers her."},
	{"id": "haniwa_charge", "name": "Haniwa Charge", "description": "Press D to charge forward, invincible, with your weapon."},
	{"id": "ceramic_barrage", "name": "Ceramic Barrage", "description": "Press F to summon a Haniwa that shoots danmaku at Saki."},
]

const STORY_UPGRADES := [
	{"id": "haniwa_wall", "name": "Haniwa Wall", "description": "Press S to raise a wall that damages Saki and reflects her danmaku."},
	{"id": "ceramic_skin", "name": "Ceramic Skin", "description": "Your body hardens into clay."},
	{"id": "haniwa_armor", "name": "Haniwa Armor", "description": "Saki's phase 1 attacks can no longer hurt you."},
]

enum Act { ACT_1, ACT_2, ACT_3 }

var victory := false
var current_try: int = 1
var deaths: int = 0
var intro_seen := false

var act_1_defeats: int = 0
var act_2_defeats: int = 0
var act_3_defeats: int = 0
var fights_started: int = 0
var phase_2_reached_this_fight: bool = false

var seen_a1_intro := false
var seen_a1_first_fight := false
var seen_a1_first_defeat := false
var seen_a1_first_upgrade := false
var seen_a1_phase2 := false

var seen_a2_ceramic_skin := false
var seen_a2_first_fight := false
var seen_a2_first_defeat := false
var seen_a2_first_upgrade := false
var seen_a2_phase2 := false

var seen_a3_armored := false
var seen_a3_first_fight := false
var seen_a3_phase2 := false

var health_tier: int = 0
var damage_tier: int = 0
var unlocked_abilities: Array[String] = []
var story_index: int = 0
var upgrades_taken: int = 0

var kiln_mode: String = "upgrade"
var last_story_upgrade: Dictionary = {}


func _ready() -> void:
	if OS.is_debug_build():
		add_child(load("res://Assets/Scripts/Core/DebugCommands.gd").new())


func reset_run() -> void:
	victory = false
	current_try = 1
	deaths = 0
	intro_seen = false
	act_1_defeats = 0
	act_2_defeats = 0
	act_3_defeats = 0
	fights_started = 0
	phase_2_reached_this_fight = false
	seen_a1_intro = false
	seen_a1_first_fight = false
	seen_a1_first_defeat = false
	seen_a1_first_upgrade = false
	seen_a1_phase2 = false
	seen_a2_ceramic_skin = false
	seen_a2_first_fight = false
	seen_a2_first_defeat = false
	seen_a2_first_upgrade = false
	seen_a2_phase2 = false
	seen_a3_armored = false
	seen_a3_first_fight = false
	seen_a3_phase2 = false
	health_tier = 0
	damage_tier = 0
	unlocked_abilities.clear()
	story_index = 0
	upgrades_taken = 0
	kiln_mode = "upgrade"
	last_story_upgrade = {}



func get_max_hearts() -> int:
	return BASE_HEARTS + health_tier


func get_damage_multiplier() -> float:
	return 1.0 + DAMAGE_PER_TIER * float(damage_tier)


func is_full_haniwa() -> bool:
	return story_index >= STORY_UPGRADES.size()


func has_story_upgrade(id: String) -> bool:
	for i in range(story_index):
		if STORY_UPGRADES[i]["id"] == id:
			return true

	return false


func apply_to_mayumi(mayumi) -> void:
	var stats := mayumi.get_node_or_null("Stats") as CharacterStats

	if stats != null:
		stats.max_health = get_max_hearts()
		stats.health = stats.max_health

	var ability_manager = mayumi.get("ability_manager")

	if ability_manager != null:
		var ids: Array[int] = [
			AbilityIDs.Ability.DASH,
			AbilityIDs.Ability.ATTACK,
		]

		for id in unlocked_abilities:
			if AbilityManager.ABILITY_STRING_TO_INT.has(id):
				ids.append(AbilityManager.ABILITY_STRING_TO_INT[id])

		if unlocked_abilities.has("arrow_volley"):
			ids.append(AbilityIDs.Ability.DANMAKU)

		if has_story_upgrade("haniwa_wall"):
			ids.append(AbilityIDs.Ability.HANIWA_WALL)

		for id in ids:
			ability_manager.unlock_ability(id)
			ability_manager.equip_ability(id)

	var multiplier := get_damage_multiplier()

	var sword = mayumi.get_node_or_null("Abilities/SwordAttack")

	if sword != null:
		sword.damage = roundi(sword.damage * multiplier)

	var danmaku = mayumi.get_node_or_null("Abilities/DanmakuShot")

	if danmaku != null:
		danmaku.projectile_damage = roundi(danmaku.projectile_damage * multiplier)

	if has_story_upgrade("ceramic_skin") and mayumi.has_method("unlock_ceramic_skin"):
		mayumi.unlock_ceramic_skin()

	if has_story_upgrade("haniwa_armor") and mayumi.has_method("unlock_haniwa_armor"):
		mayumi.unlock_haniwa_armor()


func get_fight_track() -> String:
	var attempt := deaths + 1

	if attempt <= FIGHT_THEME_1_LAST_ATTEMPT:
		return "keiki_theme_1"

	if attempt <= FIGHT_THEME_2_LAST_ATTEMPT:
		return "keiki_theme_2"

	return "keiki_theme_final"


func get_shop_track() -> String:
	if deaths <= SHOP_COLD_LAST_DEATH:
		return "shop_cold"

	return "shop_warm"


func play_music(track: String, start_at: float = 0.0) -> void:
	var music := get_node_or_null("/root/MusicManager")

	if music != null:
		music.play(track, start_at)


func get_current_act() -> int:
	if has_story_upgrade("haniwa_armor") or seen_a3_armored:
		return Act.ACT_3
	elif has_story_upgrade("ceramic_skin") or seen_a2_ceramic_skin:
		return Act.ACT_2
	return Act.ACT_1


func get_fight_dialog() -> int:
	var act := get_current_act()
	fights_started += 1
	phase_2_reached_this_fight = false

	match act:
		Act.ACT_1:
			if not seen_a1_intro:
				seen_a1_intro = true
				return DialogManager.situations.A1_INTRO
			elif not seen_a1_first_fight:
				seen_a1_first_fight = true
				return DialogManager.situations.A1_A
			elif fights_started == 3:
				return DialogManager.situations.A1_D
			else:
				return DialogManager.situations.A1_F

		Act.ACT_2:
			if not seen_a2_first_fight:
				seen_a2_first_fight = true
				return DialogManager.situations.A2_B
			elif act_2_defeats == 1:
				return DialogManager.situations.A2_E
			else:
				return DialogManager.situations.A1_F  # random banter, avoid replaying opening scene

		Act.ACT_3:
			if not seen_a3_first_fight:
				seen_a3_first_fight = true
				return DialogManager.situations.A3_B
			else:
				return DialogManager.situations.A3_F

	return DialogManager.situations.A1_F


func get_phase_2_dialog() -> int:
	phase_2_reached_this_fight = true
	var act := get_current_act()

	match act:
		Act.ACT_1:
			if not seen_a1_phase2:
				seen_a1_phase2 = true
				return DialogManager.situations.A1_H
		Act.ACT_2:
			if not seen_a2_phase2:
				seen_a2_phase2 = true
				return DialogManager.situations.A2_G
		Act.ACT_3:
			if not seen_a3_phase2:
				seen_a3_phase2 = true
				return DialogManager.situations.A3_C

	return -1


func get_defeat_dialog() -> int:
	var act := get_current_act()

	match act:
		Act.ACT_1:
			act_1_defeats += 1
			if not seen_a1_first_defeat:
				seen_a1_first_defeat = true
				return DialogManager.situations.A1_B
			else:
				return DialogManager.situations.A1_G

		Act.ACT_2:
			act_2_defeats += 1
			if not seen_a2_first_defeat:
				seen_a2_first_defeat = true
				return DialogManager.situations.A2_C
			else:
				return DialogManager.situations.A2_F

		Act.ACT_3:
			act_3_defeats += 1
			return DialogManager.situations.A3_D

	return DialogManager.situations.A1_G


func get_workshop_pre_dialog() -> int:
	var act := get_current_act()

	match act:
		Act.ACT_1:
			if not seen_a1_first_upgrade:
				seen_a1_first_upgrade = true
				return DialogManager.situations.A1_C_PRE
			else:
				return DialogManager.situations.A1_E_PRE

		Act.ACT_2:
			if not seen_a2_ceramic_skin:
				seen_a2_ceramic_skin = true
				return DialogManager.situations.A2_A
			elif not seen_a2_first_upgrade:
				seen_a2_first_upgrade = true
				return DialogManager.situations.A2_D_PRE
			else:
				return DialogManager.situations.A2_H_PRE

		Act.ACT_3:
			if not seen_a3_armored:
				seen_a3_armored = true
				return DialogManager.situations.A3_A
			else:
				return DialogManager.situations.A3_E_PRE

	return DialogManager.situations.A1_E_PRE


func get_workshop_post_dialog() -> int:
	var act := get_current_act()

	match act:
		Act.ACT_1:
			if seen_a1_first_upgrade and upgrades_taken == 1:
				return DialogManager.situations.A1_C_POST
			else:
				return DialogManager.situations.A1_E_POST

		Act.ACT_2:
			if seen_a2_first_upgrade and upgrades_taken == (UPGRADES_PER_STORY + 1):
				return DialogManager.situations.A2_D_POST
			else:
				return DialogManager.situations.A2_H_POST

		Act.ACT_3:
			return DialogManager.situations.A3_E_POST

	return -1


func get_ending_dialog() -> int:
	if upgrades_taken == 0:
		return DialogManager.situations.ENDING_1   # Ghost Matriarch (secret - 0 upgrades)
	elif get_current_act() == Act.ACT_3:
		return DialogManager.situations.ENDING_3   # Canon - Haniwa Lance Corporal
	else:
		return DialogManager.situations.ENDING_2   # Remorseful Sentinel (early victory)



func get_upgrade_offer() -> Array[UpgradeStruct]:
	var offer: Array[UpgradeStruct] = []

	if health_tier < MAX_HEALTH_TIER:
		offer.append(UpgradeStruct.new(UpgradeStruct.Type.HEALTH, "Clay Heart", 1.0))

	if damage_tier < MAX_DAMAGE_TIER:
		offer.append(UpgradeStruct.new(UpgradeStruct.Type.DAMAGE, "Sharpened Clay", DAMAGE_PER_TIER))

	var next_ability := get_next_ability_index()

	if next_ability >= 0:
		offer.append(UpgradeStruct.new(UpgradeStruct.Type.ABILITY, ABILITY_POOL[next_ability]["name"], 0.0, next_ability))

	return offer


func get_next_ability_index() -> int:
	for i in range(ABILITY_POOL.size()):
		if not unlocked_abilities.has(ABILITY_POOL[i]["id"]):
			return i

	return -1


func describe_upgrade(upgrade: UpgradeStruct) -> String:
	match upgrade.type:
		UpgradeStruct.Type.HEALTH:
			return "+1 heart (%d → %d)" % [get_max_hearts(), get_max_hearts() + 1]
		UpgradeStruct.Type.DAMAGE:
			return "+20%% sword and danmaku damage (tier %d → %d)" % [damage_tier, damage_tier + 1]
		UpgradeStruct.Type.ABILITY:
			return ABILITY_POOL[upgrade.ability_index]["description"]

	return ""


func _select_upgrade(upgrade: UpgradeStruct) -> void:
	match upgrade.type:
		UpgradeStruct.Type.HEALTH:
			health_tier = mini(health_tier + 1, MAX_HEALTH_TIER)
		UpgradeStruct.Type.DAMAGE:
			damage_tier = mini(damage_tier + 1, MAX_DAMAGE_TIER)
		UpgradeStruct.Type.ABILITY:
			unlocked_abilities.append(ABILITY_POOL[upgrade.ability_index]["id"])

	upgrades_taken += 1
	last_story_upgrade = {}

	if upgrades_taken % UPGRADES_PER_STORY == 0 and story_index < STORY_UPGRADES.size():
		last_story_upgrade = STORY_UPGRADES[story_index]
		story_index += 1

	upgrade_taken.emit(upgrade)


func on_player_died() -> void:
	if victory:
		return

	deaths += 1


func continue_after_death() -> void:
	kiln_mode = "upgrade"
	_change_scene(KILN_SCENE)


func on_boss_defeated() -> void:
	if victory:
		return

	victory = true
	kiln_mode = "win"


func show_end_screen() -> void:
	_change_scene(KILN_SCENE)


func start_fight() -> void:
	current_try += 1
	_change_scene(FIGHT_SCENE)


func start_new_run() -> void:
	reset_run()
	_change_scene(FIGHT_SCENE)


func go_to_menu() -> void:
	reset_run()
	_change_scene(MENU_SCENE)


func _change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
