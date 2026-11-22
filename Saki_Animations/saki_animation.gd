extends Node2D

@export var root: Node2D
@export var mayumi: Mayumi
@onready var anim_tree = $AnimationTree as AnimationTree

var parent : SakiController
var attack_manager: AttackManager
var last_facing_direction = 1.0
var original_scale: Vector2

func _ready() -> void:
	parent = get_parent()
	attack_manager = parent.get_node("AttackManager") as AttackManager
	
	root = self
	original_scale = root.scale

func _physics_process(delta: float) -> void:
	if parent == null:
		return

	if anim_tree != null:
		anim_tree.set("parameters/Idle-run/blend_position", parent.velocity.x)
		anim_tree.set("parameters/conditions/Dive", parent.is_jumping)
		anim_tree.set("parameters/conditions/Charge", attack_manager.get_node("Charge").is_charging)
		anim_tree.set("parameters/conditions/danmaku", attack_manager.get_node("NormalDanmaku").is_casting)
		anim_tree.set("parameters/conditions/dan_comeback", attack_manager.get_node("ComebackDanmaku").is_casting)
		anim_tree.set("parameters/conditions/dan_rain", attack_manager.get_node("DanmakuRain").is_casting)
		anim_tree.set("parameters/conditions/Tec_Punch", attack_manager.get_node("TectonicPush").is_executing)
		anim_tree.set("parameters/conditions/unleash", attack_manager.get_node("Unleash").is_unleashing)
		anim_tree.set("parameters/conditions/Taunt", attack_manager.get_node("Counter").is_posing)

	if mayumi == null:
		return

	if mayumi.global_position.x > parent.global_position.x:
		last_facing_direction = -1.0
	elif mayumi.global_position.x < parent.global_position.x:
		last_facing_direction = 1.0

	root.scale = Vector2(
		absf(original_scale.x) * last_facing_direction,
		original_scale.y
	)
