extends Panel

@export var DefaultSubpanel:Node
@export var DeletionCheckSubpanel:Node

@export var NameEdit:LineEdit
@export var AddressEdit:LineEdit
@export var PortSpinBox:SpinBox

var selectedWorldName:String
var newWorldName:String
var newWorldPort:int
var newWorldAddress:String

var isJoined:bool
var nameGotChanged:bool = false

func _ready():
	selectedWorldName = Main.SceneArgs["SelectedWorld"]
	newWorldName = selectedWorldName
	var tWorld:Dictionary = Main.M.Game_Manager.worlds[selectedWorldName]
	
	NameEdit.text = selectedWorldName
	
	isJoined = tWorld.has("Address")
	AddressEdit.get_parent().visible = isJoined
	if isJoined: 
		AddressEdit.text = tWorld["Address"]
		newWorldAddress = tWorld["Address"]
		
	newWorldPort = tWorld["Port"]
	PortSpinBox.value = tWorld["Port"]


func _on_play_button_button_down():
	actualPropertyUpdateProcess()
	Main.M.Game_Manager.loadGame(Main.SceneArgs["SelectedWorld"])


func _on_delete_button_button_down():
	DefaultSubpanel.visible = false
	DeletionCheckSubpanel.visible = true


func _on_cancel_button_button_down():
	DefaultSubpanel.visible = true
	DeletionCheckSubpanel.visible = false


func _on_final_delete_button_button_down():
	GameManager.deleteGame(Main.SceneArgs["SelectedWorld"])
	Main.M.UI.goBack()


func _on_back_button_down():
	actualPropertyUpdateProcess()
	Main.M.UI.goBack()
	
func actualPropertyUpdateProcess():
	var newName:String = Main.M.Game_Manager.createUniqueName(newWorldName) if nameGotChanged else newWorldName
	
	var tWorld:Dictionary = Main.M.Game_Manager.worlds[selectedWorldName]
	Main.M.Game_Manager.worlds.erase(selectedWorldName)
	
	if isJoined: 
		tWorld["Address"] = newWorldAddress
	tWorld["Port"] = newWorldPort
	
	Main.M.Game_Manager.worlds[newName] = tWorld
	selectedWorldName = newName


func _on_world_name_edit_text_changed(new_text):
	newWorldName = new_text
	nameGotChanged = true

func _on_address_edit_text_changed(new_text):
	newWorldAddress = new_text

func _on_port_spin_box_value_changed(value):
	newWorldPort = value


func _on_copy_button_button_down():
	actualPropertyUpdateProcess()
	Main.SceneArgs["WorldCreationProcess"] = 3
	Main.SceneArgs["CopyWorldName"] = newWorldName
	Main.M.UI.loadScene("BasicWorldInfos")
