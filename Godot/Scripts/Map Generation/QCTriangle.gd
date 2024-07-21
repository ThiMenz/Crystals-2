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

func getSquareBounds() -> Vector4i:
	var bounds = Vector4i(INF, -INF, INF, -INF) #x_min, x_max, y_min, y_max
	for vec:Vector2i in edges:
		bounds.x = min(ceil(vec.x), bounds.x)
		bounds.z = min(ceil(vec.y), bounds.z)
		bounds.y = max(floor(vec.x), bounds.y)
		bounds.w = max(floor(vec.y), bounds.w)
	return bounds

func getInnerBaseGridCoords():
	var bounds:Vector4i = getSquareBounds()
	
	var borderDijkstraFrontiers = [
		Vector2i(bounds.x, bounds.z), Vector2i(bounds.y, bounds.z),
		Vector2i(bounds.x, bounds.w), Vector2i(bounds.y, bounds.w)]
	var borderDijkstraVisDict:Dictionary = {}
	var borderTriangles:Dictionary = {}
	var innerTriangles:Dictionary = {}
	
	while len(borderDijkstraFrontiers) != 0:	
		var nextFrontiers = []
		for point:Vector2i in borderDijkstraFrontiers:
			borderDijkstraVisDict[point] = true
			for neighbor in Utils.GetVec2iNeighbors(point):				
				if borderDijkstraVisDict.has(neighbor) || !Utils.Vec2iInBox(point, bounds.x, bounds.y, bounds.z, bounds.w): continue		
				borderDijkstraVisDict[point] = true
				nextFrontiers.append(neighbor)
		
		borderDijkstraFrontiers = nextFrontiers
