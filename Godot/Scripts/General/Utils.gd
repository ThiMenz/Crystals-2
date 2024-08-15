class_name Utils

const ALMOST_INF := 999_999_999_999_999_999
const ALMOST_MINUS_INF := -999_999_999_999_999_999

const P2_30 := 2 ** 30
const PM2_30 := -(2 ** 30)


## Only 143/ms omh
static func Linecast3D(pStartPos:Vector3, pTargetPos:Vector3) -> Vector3:
	var pRaycast:RayCast3D = Main.LinecastObj
	pRaycast.position = pStartPos
	pRaycast.target_position = pTargetPos
	pRaycast.force_raycast_update()
	if !pRaycast.is_colliding(): return pTargetPos
	return pRaycast.get_collision_point() - pStartPos
	
	#print(">>")
	#print(pRaycast.get_collision_point())
	#print(pStartPos)
	#print(pTargetPos)
	#print(pRaycast.get_collision_point() - pStartPos)
	
	## Rounded on 2 decimals, because otherwise floating point issues cause too high values on some specific distances
	#return floor((pRaycast.get_collision_point() - pStartPos).length() / pTargetPos.length() * 100) / 100.

## Get closest collision safe fraction independent of the physics cycle
static func GetShapecast3DCCSF(pShapecast:ShapeCast3D, pTargetPos:Vector3) -> float:
	pShapecast.target_position = pTargetPos
	pShapecast.force_shapecast_update()
	return pShapecast.get_closest_collision_safe_fraction()

static func GetAverageVec2(pArr:Array) -> Vector2:
	var rVec:Vector2 = Vector2(0, 0)
	for vec in pArr: rVec += vec
	return rVec / len(pArr)
	
static func GetSavableQCTriangleArray(pArr:Dictionary) -> Array[Vector3i]:
	var rArr : Array[Vector3i] = []
	for t:QCTriangle in pArr: rArr.append(t.getSaveInfo())
	return rArr

static func CreateWorldList(worldElmt, worldVBoxContainer):
	var worlds = SaveSystem.D("Worlds")
	if worlds != null:
		for worldName:String in worlds:
			var elmt:WorldSelectionElement = worldElmt.instantiate()
			worldVBoxContainer.add_child(elmt)
			elmt.worldName = worldName
			elmt.update()

## This is my own formula, but that one should work ;)
static func GetClosestVec2OnLine(lineStart:Vector2, lineEnd:Vector2, pos:Vector2):
	var dirVec:Vector2 = lineEnd - lineStart	
	return lineStart + (-dirVec * (lineStart - pos)) / dirVec.length_squared() * dirVec

static func GetPosBetweenTwoVec2s(startPoint: Vector2, endPoint: Vector2, shiftVal: float):
	return startPoint + (endPoint - startPoint) * shiftVal
	
static func GetPosBetweenTwoVec3s(startPoint: Vector3, endPoint: Vector3, shiftVal: float):
	return startPoint + (endPoint - startPoint) * shiftVal

static func Vec2iInBox(vec:Vector2i, minX:int, maxX:int, minY:int, maxY:int) -> bool:
	return vec.x >= minX && vec.x <= maxX && vec.y >= minY && vec.y <= maxY

static func ConvertVec2ToVec3(vec:Vector2, yOffset:float=0.0):
	return Vector3(vec.x, yOffset, vec.y)

static func GetVec2iNeighbors(vec:Vector2i) -> Array[Vector2i]:
	return [vec+Vector2i(1,0), vec-Vector2i(1,0), vec+Vector2i(0,1), vec-Vector2i(0,1)]
	
static func GetVec2i4UnderneathNeighbors(vec:Vector2i) -> Array[Vector2i]:
	return [vec+Vector2i(1,0), vec+Vector2i(1,1), vec+Vector2i(0,1), vec+Vector2i(-1,1)]

static func Vec2iTriangleSign(p1:Vector2i, p2:Vector2i, p3:Vector2i) -> float:
	return (p1.x-p3.x) * (p2.y-p3.y) - (p2.x-p3.x) * (p1.y-p3.y)

static func Vec2InTriangle(vec:Vector2, p0:Vector2, p1:Vector2, p2:Vector2) -> bool:
	var dX = vec.x-p2.x
	var dY = vec.y-p2.y
	var dX21 = p2.x-p1.x
	var dY12 = p1.y-p2.y
	var D = dY12*(p0.x-p2.x) + dX21*(p0.y-p2.y)
	var s = dY12*dX + dX21*dY
	var t = (p2.y-p0.y)*dX + (p0.x-p2.x)*dY
	if D < 0: return s <= 0 && t <= 0 && s + t >= D
	return s >= 0 && t >= 0 && s+t <= D
