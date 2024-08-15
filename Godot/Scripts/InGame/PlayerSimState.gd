class_name PlayerSimState

var position: Vector3
var obj: Node

func _init(pObj):
	obj = pObj
	set_state(pObj.position)
	
func _copy(pCopy: PlayerSimState):
	position = pCopy.position
	
func set_state(pPosition):
	position = pPosition

func interpolate(pGoalState, pDelta):
	obj.position = Utils.GetPosBetweenTwoVec3s(position, pGoalState.position, pDelta)
