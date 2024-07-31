extends Panel

@export var WorldSelectionElement:PackedScene
@export var WorldVBoxContainer:Node

func _enter_tree(): #could theoratically swap to _ready(), right?
	var worlds = SaveSystem.D("Worlds")
	if worlds != null:
		for world:Dictionary in worlds:
			var elmt = WorldSelectionElement.instantiate()
			WorldVBoxContainer.add_child(elmt)


func _on_back_button_down():
	Main.M.UI.goBack()


func _on_create_new_button_down():
	Main.M.UI.loadScene("WorldCreationProcess")
