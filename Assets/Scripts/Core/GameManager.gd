extends Node
class_name GameplayManager

var victory = false
var max_try: int = 5 


func _change_scene(player_win: bool, current_try: int):
	victory = player_win
	get_tree().change_scene_to_file("") #insert dialogue scene path here
	
	#Placeholder for the dialogue system calls and ending checks
	#for each dialogue after a fight 
	if current_try < max_try:
		#DialogueManager._play_dialogue(SAKITAUNT)
		return
	elif current_try == max_try:
		#EndingManager._checkEnding(current_try)
		#DialogueManager._play_dialogue(MAYUMILOSE)
		return
	else:
		#EndingManager._checkEnding(current_try)
		#DialogueManager._play_dialogue(MAYUMIWIN)
		return
	
	#send the upgrade data to the upgrade manager from the selection UI
func _select_upgrade(upgrade: UpgradeStruct):
	#UpgradeManager._add_update(upgrade)
	return
