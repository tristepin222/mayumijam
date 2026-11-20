extends Node
class_name GameplayManager

var victory = false
var maxTry: int = 5 


func _change_scene(playerWin: bool, currentTry: int):
	victory = playerWin
	get_tree().change_scene_to_file("") #insert dialogue scene path here
	
	#Placeholder for the dialogue system calls and ending checks
	#for each dialogue after a fight 
	if currentTry < maxTry:
		#DialogueManager._play_dialogue(SAKITAUNT)
		return
	elif currentTry == maxTry:
		#EndingManager._checkEnding(currentTry)
		#DialogueManager._play_dialogue(MAYUMILOSE)
		return
	else:
		#EndingManager._checkEnding(currentTry)
		#DialogueManager._play_dialogue(MAYUMIWIN)
		return
	
	#send the upgrade data to the upgrade manager from the selection UI
func _select_upgrade(upgrade: UpgradeStruct):
	#UpgradeManager._add_update(upgrade)
	return
