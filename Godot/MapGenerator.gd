class_name MapGen extends Node3D

@export var PointObject: PackedScene
@export var PolygonObject: PackedScene
@export var DebugMaterial1: Material
@export var DebugMaterial2: Material
	
var rng = RandomNumberGenerator.new()

func _ready():
	
	VRNG.set_seed(rng.randi())
	
	var timestamp = Time.get_ticks_usec()
	BBG([get_QC(Vector2i(0,0)).triangle1], [[0.01]], [100]) #[[0.08], [0]], [100, 3]
	print(Time.get_ticks_usec()-timestamp)
	print(QCs.size())
	return
	
	instantiateBaseTriangles(90)
	
	Engine.max_fps = 165
	
	print(rng.seed)
	
	pass # Replace with function body.

#region ** MAP GENERATION **

#region ** QC Management **

var QCs:Dictionary = {}

func get_QC(pPos:Vector2i):
	if QCs.has(pPos): 
		return QCs[pPos]
		
	var tQC = QC.new(pPos, self)
	QCs[pPos] = tQC
	
	return tQC

#endregion

#region ** Biom Border Gen **

func BBGDegration(pVal:int, args:Array) -> float:
	return 2. ** (-args[0]*pVal)

func BBG(pStartTriangle:Array,pChanceDegrationFunc:Array, pMaxDepth:Array):
	
	var ccount:int = 1
	
	var visitedTriangles = {}
	var frontierTriangles = pStartTriangle
	
	for s in len(pChanceDegrationFunc):
	
		var tDegrationParams:Array = pChanceDegrationFunc[s]
		var lastIterTriangles = []
			
		for i in range(pMaxDepth[s]):
			
			print(str(i) + ": " + str(ccount))
			
			if len(frontierTriangles) == 0: break
			
			var chance:float = BBGDegration(i, tDegrationParams)
			var newFrontierTriangles = []	
			for t in range(0, len(frontierTriangles)):
				var tTriangle:QCTriangle = frontierTriangles[t]
				
				if VRNG.rand(tTriangle.qc.pos * 3 + (Vector2i(1,1) if tTriangle.sideO else Vector2i(0,0))) < chance:
					var tNeighbors:Array = tTriangle.getNeighbors()
					
					for n in range(3):
						var tneighbor = tNeighbors[n]
						if visitedTriangles.has(tneighbor): continue
						
						newFrontierTriangles.append(tneighbor)
						lastIterTriangles.append(tneighbor)
						visitedTriangles[tneighbor] = true
						ccount += 1
						
						var polyObj = PolygonObject.instantiate()
						add_child(polyObj)
						polyObj.polygon = PackedVector2Array(tneighbor.edges)
						polyObj.material = DebugMaterial1 if i == 16 else DebugMaterial2
			frontierTriangles = newFrontierTriangles
		
		frontierTriangles = lastIterTriangles
		
		
	#for t in visitedTriangles:
	#	
	#	var polyObj = PolygonObject.instantiate()
	#	add_child(polyObj)
	#	print(t.edges[0])
	#	polyObj.polygon = PackedVector2Array(t.edges)
	#	#polyObj.material = DebugMaterial1 if t.debugDiagonal else DebugMaterial2
		
		
	print("BBG END " + str(ccount))
	
func BBGRecursive(pDepth:int, pMaxDepth:int, pChanceAtDepth:Array):
	
	if pDepth == pMaxDepth: return
	
	BBGRecursive(pDepth + 1, pMaxDepth, pChanceAtDepth)

#endregion

#region ** BASE TRIANGLES **

@export_category("BaseTriangles")
@export var origin : Vector2
@export var gridDist : Vector2
@export var randomizationStrength : Vector2

var triangles = []
func instantiateBaseTriangles(pSize: int):
	var tvec2 : Vector2 = origin
	var rngEgdePoints = []
	
	var tTimeStamp:int = Time.get_ticks_msec()
	
	for i in range(0, pSize):	
		rngEgdePoints.append([])
		for j in range(0, pSize):
			var tPos : Vector2 = randomizeBaseTrianglePosition(tvec2)
			rngEgdePoints[i].append(tPos)
			tvec2.x += gridDist.x
			
		tvec2.x = origin.x
		tvec2.y += gridDist.y	
	
	print(Time.get_ticks_msec()-tTimeStamp)
	
	for i in range(0, pSize-1):
		for j in range(0, pSize-1):
			var tSquare = getSquareOfPointIdx(i, j, rngEgdePoints)
			var diagonalDir : bool = !rng.randi_range(0, 1)
				
			triangles.append(MapTriangle.new([tSquare[0], tSquare[1], tSquare[2]] 
			if diagonalDir else [tSquare[2], tSquare[0], tSquare[3]], true))
			triangles.append(MapTriangle.new([tSquare[3], tSquare[1], tSquare[2]] 
			if diagonalDir else [tSquare[3], tSquare[0], tSquare[1]], false))
			
	print(Time.get_ticks_msec()-tTimeStamp)
			
	var tpr : int = pSize * 2 - 2 # abbreviation for trianglesPerRow
	var triangleCount : int = len(triangles)
	for i in range(0, triangleCount, 2):
		var idxsForSquares : Array = [i-1,i-2,i-tpr,i-tpr+1]
		checkForNeighborTriangleByIDs(triangles[i], idxsForSquares, triangleCount)
		checkForNeighborTriangleByIDs(triangles[i+1], idxsForSquares + [i], triangleCount)
	
	print(Time.get_ticks_msec()-tTimeStamp)
	
	for t in triangles:	
		var polyObj = PolygonObject.instantiate()
		add_child(polyObj)
		polyObj.polygon = PackedVector2Array(t.edges)
		polyObj.material = DebugMaterial1 if t.debugDiagonal else DebugMaterial2

func getSquareOfPointIdx(pX : int, pY: int, pPoints : Array):
	return [pPoints[pX][pY], pPoints[pX + 1][pY], pPoints[pX][pY + 1], pPoints[pX + 1][pY + 1]]
	
func randomizeBaseTrianglePosition(pPos: Vector2) -> Vector2:
	return Vector2(
		pPos.x + rng.randf_range(-randomizationStrength.x, randomizationStrength.x),
		pPos.y + rng.randf_range(-randomizationStrength.y, randomizationStrength.y)
	)
	
func checkForNeighborTriangleByIDs(pTriangle : MapTriangle, pIdxs : Array, maxTriangleID : int):
	for i in pIdxs:
		if i < 0 || (i > maxTriangleID - 1): continue
		pTriangle.checkForNeighborTriangle(triangles[i])
		
	
	
#endregion

#endregion

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
