extends Panel

@export var SeedInpField:LineEdit

var curSeed:int = -1

func _on_check_button_toggled(toggled_on):
	SeedInpField.editable = !toggled_on
	if toggled_on:
		SeedInpField.text = ""
		SeedInpField.placeholder_text = "Random"
		curSeed = -1
	else:
		SeedInpField.placeholder_text = "e.g. 123456789"

func _on_seed_edit_text_changed(new_text):
	var tSeed = int(new_text)
	curSeed = abs(tSeed)

func _on_back_button_down():
	Main.M.UI.goBack()

func _on_button_button_down():
	var sceneArgs := Main.M.SceneArgs
	sceneArgs["WorldSeed"] = curSeed
	Main.M.Game_Manager.loadNewGame(GameManager.getInfosFromSceneArgs())
