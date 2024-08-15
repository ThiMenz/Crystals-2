extends Panel

@export var statusLabel:Label
	
func changeStatus(statusText:String):
	statusLabel.text = statusText

func _on_back_button_down():
	Main.M.UI.goBack()
