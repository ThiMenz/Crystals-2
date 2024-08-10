class_name TranslationCUOWAState

var position:Vector3
var rotation:Vector3
var scale:Vector3
var obj:Node

func _init(pObj:Node):
	obj = pObj

func set_state():
	position = obj.position
	rotation = obj.rotation
	scale = obj.scale
	
