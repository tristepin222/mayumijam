extends Node2D

@onready var anim_tree = $AnimationTree as AnimationTree

var parent : SakiController
var attack_manager: AttackManager

func _ready() -> void:
	parent = get_parent()
	attack_manager = parent.get_node("AttackManager") as AttackManager
	
	if parent != null && anim_tree != null:
		anim_tree.set("parameters/Idle-run/blend_position", parent.velocity.x)
		anim_tree.set("parameters/conditions/Dive", parent.is_jumping)
		anim_tree.set("parameters/conditions/Charge", attack_manager.get_node("Charge"))
		
		
