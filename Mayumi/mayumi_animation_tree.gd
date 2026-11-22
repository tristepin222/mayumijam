extends AnimationTree

@onready var animation_tree = $AnimationTree as AnimationTree
@onready var player = get_owner().get_parent()

var last_facing_direction: int = 1
