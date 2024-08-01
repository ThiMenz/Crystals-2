class_name WorldSelectionElement extends Panel #class_name WorldSelectionElement?

@export var worldNameText:Label
var worldName = ""

func update():
	worldNameText.text = worldName

func _on_button_down():
	Main.M.worldSelected.emit(worldName)
