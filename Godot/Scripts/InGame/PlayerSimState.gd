class_name PlayerSimState

var obj: Node
var position: Vector3

func _init(pObj):
	obj = pObj
	set_state(pObj.position)
	
func _copy(pCopy: PlayerSimState):
	position = pCopy.position

func switch_to_goal():
	obj.position = position
	
func set_state(pPosition):
	position = pPosition

func interpolate(pGoalState, pDelta):
	obj.position = Utils.GetPosBetweenTwoVec3s(position, pGoalState.position, pDelta)
