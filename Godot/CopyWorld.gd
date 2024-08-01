extends Panel

@export var WorldSelectionElement:PackedScene
@export var WorldVBoxContainer:Node

func _ready():
	Utils.CreateWorldList(WorldSelectionElement, WorldVBoxContainer)
	Main.M.worldSelected.connect(on_world_select)

func on_world_select(name:String):
	print(name)
	# Load Game

func _on_back_button_down():
	Main.M.UI.goBack()
