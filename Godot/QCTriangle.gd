class_name QCTriangle

var qc : QC
var sideO : bool
var sideL : bool
var edges : Array

func _init(pQC:QC, pSideO:bool, pSideL:bool):
	qc = pQC
	sideO = pSideO
	sideL = pSideL
	if sideO: edges = [qc.edges[0], qc.edges[1], qc.edges[2]] if sideL else [qc.edges[0], qc.edges[1], qc.edges[3]]
	else: edges = [qc.edges[2], qc.edges[3], qc.edges[0]] if sideL else [qc.edges[2], qc.edges[3], qc.edges[1]]


func getNeighbors() -> Array:
	return [
		qc.triangle2 if qc.triangle1 == self else qc.triangle1,
		qc.get_horizontalTriangleNeighbor(sideL),
		qc.get_verticalTriangleNeighbor(sideO)	
		]

const BoundInf:int = 999999999
const NBoundInf:int = -999999999
func getISquareBounds() -> Vector4i:
	var bounds = Vector4i(BoundInf, NBoundInf, BoundInf, NBoundInf) #x_min, x_max, y_min, y_max
	for vec:Vector2 in edges:
		bounds.x = min(ceil(vec.x), bounds.x)
		bounds.z = min(ceil(vec.y), bounds.z)
		bounds.y = max(floor(vec.x), bounds.y)
		bounds.w = max(floor(vec.y), bounds.w)
	return bounds

func getInnerBaseGridCoords() -> Array[Vector2i]:
	var bounds:Vector4i = getISquareBounds()
	var innerPoints:Array[Vector2i] = []
	for x in range(bounds.x, bounds.y + 1):	
		for y in range(bounds.z, bounds.w + 1):
			var vec := Vector2i(x, y)
			if Utils.Vec2InTriangle(vec, edges[0], edges[1], edges[2]): innerPoints.append(vec)
					
	return innerPoints 
