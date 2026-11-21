extends Node
class_name DialogManager

var dialog_player: DialogPlayer

enum characters { MAYUMI, SAKI, KEIKI }
enum situations { INTRO, SAKITAUNT, MAYUMILOSE, MAYUMIWIN }

#func _play_dialog():

#func _input(event: InputEvent):
#	if event.is_action_pressed("update_dialog"):
#		if !dialog_opened:
#			_open_dialog(self.situations.INTRO)
#		else:
#			_continue_dialog()
