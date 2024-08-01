extends Panel

func _on_quit_btn_button_down():
	Main.M._quit()

func _on_play_btn_button_down():
	Main.M.UI.loadScene("Worlds")
