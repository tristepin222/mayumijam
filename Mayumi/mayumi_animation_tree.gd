extends AnimationTree

@export var root: Node2D
var player: Mayumi
var scale

var last_facing_direction = 1.0

func _ready() -> void:
	#await get_tree().create_timer(0.01).timeout
	player = get_parent().get_parent()
	scale = root.scale

func _physics_process(delta: float) -> void:
	
	if player != null:
		set("parameters/idle-run/blend_position", player.velocity.x)
		set("parameters/conditions/jump", player.velocity.y < 0)
		set("parameters/conditions/grounded", player.is_on_floor())
		set("parameters/conditions/attack", player.sword_ability.sword_hitbox.monitoring)
		set("parameters/conditions/dash", player.dash_ability.is_dashing)
		set("parameters/conditions/danmaku", player.danmaku_ability.is_shooting)
	
	last_facing_direction = player.velocity.x
	
	if last_facing_direction < 0:
		root.scale = Vector2 (-scale.x, scale.y)
	elif last_facing_direction > 0:
		root.scale = Vector2(scale.x, scale.y)
	else:
		pass
	
