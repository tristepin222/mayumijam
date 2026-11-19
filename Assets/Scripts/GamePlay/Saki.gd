
extends CharacterBody2D

@export_group("Movement")
@export var move_speed: float = 150.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0

@export_group("Combat")
@export var attack_damage: int = 15
@export var attack_range: float = 60.0
@export var attack_height_tolerance: float = 40.0
@export var attack_cooldown: float = 1.5

@export_group("References")
@export var player: CharacterBody2D
@export var stats: CharacterStats

var can_attack := true
var defeated := false


func _ready() -> void:
	if stats == null:
		stats = $Stats

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	stats.died.connect(_on_defeated)


func _physics_process(delta: float) -> void:
	if defeated:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	if player == null:
		velocity.x = 0.0
		move_and_slide()
		return

	var distance_x := player.global_position.x - global_position.x
	var distance_y := global_position.y - player.global_position.y

	# Check whether Mayumi is within attack range
	if abs(distance_x) <= attack_range and abs(distance_y) <= attack_height_tolerance:
		velocity.x = 0.0
		attack()
	else:
		# Chase Mayumi horizontally
		velocity.x = sign(distance_x) * move_speed

		# Jump if Mayumi is above Saki
		if distance_y > 60.0 and is_on_floor():
			velocity.y = jump_velocity

	move_and_slide()


func attack() -> void:
	if not can_attack or defeated:
		return

	can_attack = false

	if player != null:
		var distance_x: float = absf(player.global_position.x - global_position.x)
		var distance_y: float = absf(player.global_position.y - global_position.y)

		if distance_x <= attack_range and distance_y <= attack_height_tolerance:
			player.stats.take_damage(attack_damage)

	await get_tree().create_timer(attack_cooldown).timeout

	if not defeated:
		can_attack = true


func _on_defeated() -> void:
	defeated = true
	velocity = Vector2.ZERO

	hide()
	set_physics_process(false)
	set_process_input(false)

	$CollisionShape2D.set_deferred("disabled", true)
