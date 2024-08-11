extends Panel

@export var WorldSelectionElement:PackedScene
@export var WorldVBoxContainer:Node

func _ready(): #swap to _enter_tree()?
	PlayerManager.playerObjects.clear()
	Utils.CreateWorldList(WorldSelectionElement, WorldVBoxContainer)
	Main.M.worldSelected.connect(on_world_select)

func on_world_select(name:String):
	Main.M.SceneArgs["SelectedWorld"] = name
	Main.M.UI.loadScene("WorldMenu")

func _on_back_button_down():
	Main.M.UI.goBack()

func _on_create_new_button_down():
	Main.M.UI.loadScene("WorldCreationProcess")

func _on_join_new_button_down():
	Main.M.UI.loadScene("JoinWorld")
