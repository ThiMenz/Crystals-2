extends Panel

var worldName:String = "Wonderful World"
var address:String = "XXX.XXX.XXX.XXX"
var port:int = 37979

func _on_back_button_down():
	Main.M.UI.goBack()

func _on_world_name_edit_text_changed(new_text):
	worldName = new_text

func _on_address_edit_text_changed(new_text):
	address = new_text

func _on_port_spin_box_value_changed(value):
	port = value

func _on_join_button_down():
	var basicInfos := {
		"WorldName":worldName, 
		"WorldAddress":address,
		"WorldPort":port
	}
	Main.M.updateSceneArgs(basicInfos)
	Main.M.Game_Manager.loadNewGame(GameManager.getInfosFromSceneArgs())
