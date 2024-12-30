extends Panel

@export var statusLabel:Label
	
func changeStatus(statusText:String):
	statusLabel.text = statusText

func _on_back_button_down():	
	Main.M.Multiplayer.peer.close()
	Main.M.UI.goBack()
