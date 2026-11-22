
extends CharacterBody2D
class_name Mayumi

signal physical_attack_started

@export_group("Movement")
@export var move_speed: float = 250.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0

@export_group("References")
@export var stats: CharacterStats
@export var ability_manager: Node

@export_group("Ceramic Skin")
@export var ceramic_skin_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

var ceramic_skin_unlocked := false

var facing_direction: float = 1.0

var is_grazing_projectiles: bool = false
var is_invincible := false

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

func _process(_delta: float) -> void:
	if stats != null and stats.is_invulnerable:
		sprite.visible = int(Time.get_ticks_msec() / 80.0) % 2 == 0
	else:
		sprite.visible = true



func _physics_process(delta: float) -> void:
	# Dash controls Mayumi's movement while active.
	if dash_ability != null and dash_ability.is_dashing:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal movement.
	var direction := 0.0

	if Input.is_action_pressed("move_right"):
		direction += 1.0

	if Input.is_action_pressed("move_left"):
		direction -= 1.0

	velocity.x = direction * move_speed

	# Update facing direction.
	if direction != 0.0:
		facing_direction = signf(direction)

	# Jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity
		elif haniwa_leap != null:
			haniwa_leap.activate()

	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
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

	if ceramic_skin_texture != null:
		sprite.texture = ceramic_skin_texture
	else:
		push_warning("Ceramic Skin: No alternate texture assigned.")


func unlock_haniwa_armor() -> void:
	stats.immune_to_phase_one = true
	print("Haniwa Armor unlocked!")
