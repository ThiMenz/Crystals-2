extends Panel #class_name WorldSelectionElement?

var worldName = ""

func _on_button_down():
	Main.M.worldSelected.emit(worldName)
