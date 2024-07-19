class_name QC

var pos : Vector2i 
var triangle1 : QCTriangle
var triangle2 : QCTriangle
var edges : Array = []
var mapGen: MapGen

func _init(pPos:Vector2i, pMapGen:MapGen):
	pos = pPos
	mapGen = pMapGen
	set_edges()
	var b : bool = VRNG.bRand(pPos + Vector2i(331, 157)) #random
	triangle1 = QCTriangle.new(self, true, b)
	triangle2 = QCTriangle.new(self, false, !b)
	
func _to_string():
	var str = "QC(%,%,%,%)".format(edges, "%")
	return str
	
func get_verticalTriangleNeighbor(pOState:bool) -> QCTriangle:
	return mapGen.get_QC(pos+(Vector2i(0,-1) if pOState else Vector2i(0,1))).get_triangleWithO(!pOState)
	
func get_horizontalTriangleNeighbor(pLState:bool) -> QCTriangle:
	return mapGen.get_QC(pos+(Vector2i(-1,0) if pLState else Vector2i(1,0))).get_triangleWithL(!pLState)
	
func get_triangleWithO(pOState:bool) -> QCTriangle:
	return triangle1 if triangle1.sideO == pOState else triangle2

func get_triangleWithL(pLState:bool) -> QCTriangle:
	return triangle1 if triangle1.sideL == pLState else triangle2
	
func set_edges():
	edges = [
		randomizePositionOffset(pos, mapGen.randomizationStrength),
		randomizePositionOffset(pos+Vector2i(1,0), mapGen.randomizationStrength),
		randomizePositionOffset(pos+Vector2i(0,1), mapGen.randomizationStrength),
		randomizePositionOffset(pos+Vector2i(1,1), mapGen.randomizationStrength)
	]
	
static func randomizePositionOffset(pPos: Vector2i, randomizationStrength: Vector2) -> Vector2:
	return Vector2(
		pPos.x + VRNG.fRand(-randomizationStrength.x, randomizationStrength.x, pPos * 2),
		pPos.y + VRNG.fRand(-randomizationStrength.y, randomizationStrength.y, pPos * 2 + Vector2i(1,1))
	)
