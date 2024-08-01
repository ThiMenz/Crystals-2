extends Panel

func _on_back_button_down():
	Main.M.UI.goBack()


func _on_default_button_down():
	Main.M.UI.loadScene("BasicWorldInfos", { "WorldCreationProcess": 0 })


func _on_custom_button_down():
	Main.M.UI.loadScene("BasicWorldInfos", { "WorldCreationProcess": 1 })


func _on_copy_button_down():
	Main.M.UI.loadScene("BasicWorldInfos", { "WorldCreationProcess": 2 })
