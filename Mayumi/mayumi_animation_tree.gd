extends AnimationTree

var player: Mayumi

var last_facing_direction: int = 1

func _ready() -> void:
	await get_tree().create_timer(0.01).timeout
	player = get_parent().get_parent()

func _physics_process(delta: float) -> void:
	
	if player != null:
		set("parameters/idle-run/blend_position", player.velocity.x)
		set("parameters/conditions/jump", player.velocity.y < 0)
		set("parameters/conditions/grounded", player.is_on_floor())
		set("parameters/conditions/attack", player.sword_ability.sword_hitbox.monitoring)
		set("parameters/conditions/dash", player.dash_ability.is_dashing)
		set("parameters/conditions/danmaku", player.danmaku_ability.is_shooting)
