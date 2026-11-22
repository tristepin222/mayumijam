extends Node2D

#We must to change the color of the legs aswell <------
var brazo_derecho: Sprite2D
var brazo_izquierdo: Sprite2D
var helper: Node2D #Arm container Left
var helper_right: Node2D #Arm cointainer Right
var left_fingers: Sprite2D
var right_fingers: Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	brazo_derecho = get_node("Sprites/Right_ArmContainer/RightBicep")
	brazo_izquierdo = get_node("Sprites/LeftArm_container/LeftBicep")
	right_fingers = get_node("Sprites/Right_ArmContainer/RightBicep/RightFingers")
	helper = get_node("Sprites/LeftArm_container")
	helper_right = get_node("Sprites/Right_ArmContainer")
	left_fingers = get_node("Sprites/LeftArm_container/LeftBicep/LeftForearm/LetfFingers")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
				
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_LEFT:
		scale.x = -1.0
		right_fingers.visible = true
		left_fingers.visible = false
		helper_right.z_index = -3
		#Add to helper_right.global_position.x
		#Iddle -46
		#Run - 32
		#Air Atack -34
		#Jump -42
		#Danmaku -36
				
		#Add to helper.global_position.x
		#Iddle 43
		#Run 11 #Run also needs  global_position.y -10 
		#Air Atack 33
		#Jump 18
		#Danmaku 36
		
		helper_right.global_position = Vector2(helper_right.global_position.x, helper_right.global_position.y)
		helper.global_position = Vector2(helper.global_position.x ,helper.global_position.y )
		brazo_derecho.modulate = Color("f1f1f1ff")
		for node in brazo_derecho.get_children():
			if node is Sprite2D:
				node.modulate = Color("#f1f1f1ff")
			if node is Node2D and node.get_child_count() > 0:
				for sub_node in brazo_izquierdo.get_children():
					sub_node.modulate = Color("#f1f1f1ff")
			helper.z_index = 3
			brazo_izquierdo.modulate = Color(1, 1, 1, 1)
			for node_2 in brazo_izquierdo.get_children():
				if node_2 is Sprite2D:
					node_2.modulate = Color(1, 1, 1, 1)
				if node_2 is Node2D and node.get_child_count() > 0:
					for sub_node_2 in brazo_izquierdo.get_children():
						sub_node_2.modulate = Color(1, 1, 1, 1)
