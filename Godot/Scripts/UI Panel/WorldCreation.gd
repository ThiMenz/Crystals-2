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
	
	var wcp:int = Main.SceneArgs["WorldCreationProcess"]
	
	var basicInfos := {
		"WorldName":worldName, 
		"WorldPort":port
	}
	Main.M.updateSceneArgs(basicInfos)
	
	if wcp == 0: ## Default
		Main.M.Game_Manager.loadNewGame(GameManager.getInfosFromSceneArgs())
	elif wcp == 1: ## Custom
		Main.M.UI.loadScene("CustomWorld")
	elif wcp == 2: ## Indirect Copy (Select Missing)
		Main.M.UI.loadScene("CopyWorld")
	elif wcp == 3: ## Direct Copy
		var tName = Main.SceneArgs["CopyWorldName"]
		var tuniqueName := Main.M.Game_Manager.copyGame(tName)
		Main.M.Game_Manager.loadGame(tuniqueName)
	
