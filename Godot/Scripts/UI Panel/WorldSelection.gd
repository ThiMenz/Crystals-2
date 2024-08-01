extends Panel

@export var WorldSelectionElement:PackedScene
@export var WorldVBoxContainer:Node

func _ready(): #swap to _enter_tree()?
	Utils.CreateWorldList(WorldSelectionElement, WorldVBoxContainer)
	Main.M.worldSelected.connect(on_world_select)

func on_world_select(name:String):
	Main.M.Game_Manager.loadGame(name)

func _on_back_button_down():
	Main.M.UI.goBack()

func _on_create_new_button_down():
	Main.M.UI.loadScene("WorldCreationProcess")
