extends Button

var saveFileName:String = "Crystals"

func _on_button_down():
	Main.M.loadSavefile(saveFileName)
