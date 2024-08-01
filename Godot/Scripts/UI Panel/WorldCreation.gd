extends Panel

var port:int = 37979
var worldName:String = "Wonderful World"

func _on_back_button_down():
	Main.M.UI.goBack()

func _on_port_spin_box_value_changed(value):
	port = value

func _on_world_name_edit_text_changed(new_text):
	worldName = new_text


func _on_continue_button_button_down():
	
	var basicInfos := {
		"WorldName":worldName, 
		"WorldPort":port
	}
	Main.M.updateSceneArgs(basicInfos)
	
	var wcp:int = Main.SceneArgs["WorldCreationProcess"]
	if wcp == 0:
		Main.M.Game_Manager.loadNewGame(GameManager.getInfosFromSceneArgs())
	elif wcp == 1:
		Main.M.UI.loadScene("CustomWorld")
	elif wcp == 2:
		Main.M.UI.loadScene("CopyWorld")
	
