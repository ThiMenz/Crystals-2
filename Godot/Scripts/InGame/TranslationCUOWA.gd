class_name TranslationCUOWA extends NetworkCUOWA

@export var syncPosition:bool = true
@export var syncRotation:bool = false
@export var syncScale:bool = false
@export_range(1, 112) var syncTicks:int = 3

var obj:Node

func initCUOWA(pID:int, pPool:int, pObj:Node):
	updateRate = syncTicks
	initIDs(pID, pPool)
	obj = pObj
	
func getCUOWA(): 
	pass
	
func updateCUOWA(): 
	pass
