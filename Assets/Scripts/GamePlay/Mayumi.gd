
extends CharacterBody2D
class_name Mayumi

signal physical_attack_started

@export_group("Movement")
@export var move_speed: float = 250.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0
@export var fall_gravity_multiplier: float = 1.7
@export var jump_cut_multiplier: float = 0.45
@export var max_fall_speed: float = 420.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.12

@export_group("References")
@export var stats: CharacterStats
@export var ability_manager: Node

@export_group("Ceramic Skin")
@export var ceramic_skin_proxy: CeramicSkinProxy

@onready var sprite: Sprite2D = $Sprite2D

var ceramic_skin_unlocked := false

var facing_direction: float = 1.0

var is_grazing_projectiles: bool = false
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var is_invincible := false

var cinematic := false
var cinematic_direction := 0.0

var was_on_floor := true
var last_health := 0

var dash_ability: PlayerAbility
var sword_ability: PlayerAbility
var danmaku_ability: PlayerAbility
var haniwa_leap: PlayerAbility
var haniwa_wall: PlayerAbility
var haniwa_charge: PlayerAbility
var ceramic_barrage: PlayerAbility


func _ready() -> void:
	if stats == null:
		stats = $Stats
		
	if ability_manager == null:
		ability_manager = get_node("../AbilityManager")

	# Connect upgrade unlocking to Mayumi.
	ability_manager.ability_unlocked.connect(_on_ability_unlocked)

	# Apply upgrades that were already unlocked before Mayumi initialized.
	for ability_id in ability_manager.unlocked_abilities:
		apply_upgrade(ability_id)

	# Get ability references.
	dash_ability = $Abilities/Dash as PlayerAbility
	sword_ability = $Abilities/SwordAttack as PlayerAbility
	danmaku_ability = $Abilities/DanmakuShot as PlayerAbility
	haniwa_leap = $Abilities/HaniwaLeap as PlayerAbility
	haniwa_wall = $Abilities/HaniwaWall as PlayerAbility
	haniwa_charge = $Abilities/HaniwaCharge as PlayerAbility
	ceramic_barrage = $Abilities/CeramicBarrage as PlayerAbility

	# Give every ability its references.
	for ability in $Abilities.get_children():
		if ability is PlayerAbility:
			ability.setup(self, ability_manager)

	var game_manager = get_node_or_null("/root/GameManager")

	if game_manager != null:
		game_manager.apply_to_mayumi(self)
	

	# Apply upgrades that were already unlocked before Mayumi initialized.
	for ability_id in ability_manager.unlocked_abilities:
		apply_upgrade(ability_id)

	sprite.visible = not has_node("Mayumi")

	last_health = stats.health
	stats.health_changed.connect(_on_health_changed)


func _on_health_changed(current_health: int, _max_health: int) -> void:
	if current_health < last_health and current_health > 0:
		Sfx.play("clay_crush")

	last_health = current_health


func _process(_delta: float) -> void:
	var blink_off := stats != null and stats.is_invulnerable and int(Time.get_ticks_msec() / 80.0) % 2 == 1
	modulate.a = 0.25 if blink_off else 1.0
	sprite.visible = not has_node("Mayumi")



func _physics_process(delta: float) -> void:
	# Dash controls Mayumi's movement while active.
	if dash_ability != null and dash_ability.is_dashing:
		return

	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

		var current_gravity := gravity

		if velocity.y > 0.0:
			current_gravity *= fall_gravity_multiplier

		velocity.y = minf(velocity.y + current_gravity * delta, max_fall_speed)

	# Horizontal movement.
	var direction := 0.0

	if cinematic:
		direction = cinematic_direction
	else:
		if Input.is_action_pressed("move_right"):
			direction += 1.0

		if Input.is_action_pressed("move_left"):
			direction -= 1.0

	velocity.x = direction * move_speed

	# Update facing direction.
	if direction != 0.0:
		facing_direction = signf(direction)

	if cinematic:
		move_and_slide()
		return

	# Jump.
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer -= delta

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		Sfx.play("jump")
	elif Input.is_action_just_pressed("jump") and haniwa_leap != null:
		var leap_was_used: bool = haniwa_leap.get("air_jump_used")
		haniwa_leap.activate()

		if haniwa_leap.get("air_jump_used") and not leap_was_used:
			jump_buffer_timer = 0.0

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	var falling_speed := velocity.y

	move_and_slide()

	if is_on_floor() and not was_on_floor and falling_speed > 150.0:
		Sfx.play("land")

	was_on_floor = is_on_floor()


func _input(event: InputEvent) -> void:
	if cinematic:
		return

	if event.is_action_pressed("sword"):
		if sword_ability != null:
			sword_ability.activate()

	if event.is_action_pressed("dash"):
		if dash_ability != null:
			dash_ability.activate()

	if event.is_action_pressed("danmaku_shot"):
		if danmaku_ability != null:
			danmaku_ability.start_charge()

	if event.is_action_released("danmaku_shot"):
		if danmaku_ability != null:
			danmaku_ability.release_charge()

	if event.is_action_pressed("haniwa_wall"):
		if haniwa_wall != null:
			haniwa_wall.activate()

	if event.is_action_pressed("haniwa_charge"):
		if haniwa_charge != null:
			haniwa_charge.activate()

	if event.is_action_pressed("ceramic_barrage"):
		if ceramic_barrage != null:
			ceramic_barrage.activate()


# Called whenever AbilityManager unlocks an upgrade.
func _on_ability_unlocked(ability_id: int) -> void:
	apply_upgrade(ability_id)


# Applies the effects of passive and story upgrades.
func apply_upgrade(ability_id: int) -> void:
	match ability_id:
		AbilityIDs.Ability.CERAMIC_SKIN:
			unlock_ceramic_skin()

		AbilityIDs.Ability.HANIWA_ARMOR:
			unlock_haniwa_armor()


func unlock_ceramic_skin() -> void:
	ceramic_skin_unlocked = true

	if ceramic_skin_proxy != null:
		ceramic_skin_proxy.apply_ceramic_skin()
	else:
		push_warning("Mayumi: Ceramic Skin Proxy not assigned.")


func unlock_haniwa_armor() -> void:
	stats.immune_to_phase_one = true
	print("Haniwa Armor unlocked!")
