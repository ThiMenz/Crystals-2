class_name EnemyBase extends SimulationObject

@export_subgroup("Vision")
@export var visionArray:Array[VisionTypeInfo] ## Index 0 = Highest Priority
@export var visionParent:Node

enum AttackType {CRYSTAL, PLAYER, BUILDING}

@onready var pathfinder := Main.M.Simulation.TerrainGenerator.pathfinder

#region | NETWORKING |

@export_subgroup("Networking & Simulation")
@export var cuowa:NetworkCUOWA
@export var simStateType:SimulationManager.SimStateTypes

func spawn_setup(data:Array): 
	self.position = data[0]
	init_simState(self, SimulationManager.SimStateTypeDict[simStateType])
	initVision()
	cuowa.initCUOWA(self)
	Main.M.MainSceneManager.currentScene.add_child(self)

#endregion
	
#region | PATHFINDING |

var path:PackedVector2Array
var pathLength := 0 ## In reality len() - 1
var nextPathPoint := 0
var lastPathfindingGoalPoint:Vector2

func moveAlongPath(distance:float) -> Vector3:
	if pathLength == 0: return obj.global_position
	
	var curPoint:Vector2 = Vector2(curGoalState.position.x, curGoalState.position.z)
	var goalPoint := path[nextPathPoint]
	
	var remainingDist:float = distance
	var curDist:float = curPoint.distance_to(goalPoint)
	
	while curDist < remainingDist:
		remainingDist -= curDist
		if nextPathPoint == pathLength: return Vector3(goalPoint.x, 0, goalPoint.y)
		curPoint = goalPoint
		nextPathPoint += 1
		goalPoint = path[nextPathPoint]
		lastPathfindingGoalPoint = goalPoint
		curDist = curPoint.distance_to(goalPoint)
		
	var rPoint:Vector2 = curPoint + (goalPoint - curPoint).limit_length(remainingDist)
	
	return Vector3(rPoint.x, 0, rPoint.y)

func updatePath():
	if curTarget == null: return
	
	var curPos := Vector2(curGoalState.position.x, curGoalState.position.z)
	var startPoint:int = pathfinder.get_closest_point(curPos)
	var targetPos := Vector2(curTarget.global_position.x, curTarget.global_position.z)
	var endPoint:int = pathfinder.get_closest_point(targetPos)
	
	nextPathPoint = 0
	path = pathfinder.get_point_path(startPoint, endPoint)
	if len(path) > 1 && path[1] == lastPathfindingGoalPoint:
		nextPathPoint = 1
		
	pathLength = len(path)
	path.append(targetPos)

#endregion
	
#region | VISION |

var visionObjects:Array[Node] = []
var curTarget:Node = null

func initVision(): ##0.5ms omh
	var vd_obj:PackedScene = Main.M.spwnCarrier.VisionDetectionObject
	
	for typeInfo:VisionTypeInfo in visionArray:
		var tVD:Node = vd_obj.instantiate()
		visionParent.add_child(tVD)
		visionObjects.append(tVD)
		tVD.set_radius(typeInfo.radius)
		tVD.set_type(typeInfo.type)

func updateTarget():
	curTarget = null
	for visionObj:VisionDetector in visionObjects:
		var tTarget := visionObj.get_closest_collider_to(visionParent.global_position)
		if tTarget != null:
			curTarget = tTarget
			return
			
	pathLength = 0
	
#endregion
