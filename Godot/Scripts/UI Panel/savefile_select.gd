extends Panel

@export var VBOXObj:Node
@export var BtnSpwn:PackedScene

func _ready():	
	for saveFileName:String in Main.SaveFileNames:
		var tObj := BtnSpwn.instantiate()
		tObj.text = saveFileName
		VBOXObj.add_child(tObj)
		tObj.saveFileName = saveFileName
