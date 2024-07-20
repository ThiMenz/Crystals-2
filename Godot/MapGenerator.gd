class_name MapGen extends Node3D

@export var PointObject: PackedScene
@export var PolygonObject: PackedScene
@export var DebugMaterial1: Material
@export var DebugMaterial2: Material
@export var DebugMaterials:Array[Material]
@export var TestBiomInfo:BiomInfo

@export var randomizationStrength : Vector2

var rng = RandomNumberGenerator.new()

func _ready():

	Engine.max_fps = 165
	
	var seed = rng.randi()
	print(seed)
	
	VRNG.set_seed(seed) # seed
	
	var v = GenerateBasePropertiesOfBiom(get_QC(Vector2i(0,0)).triangle1, TestBiomInfo)
	for triangle in v["All"]:
		var polyObj = PolygonObject.instantiate()
		add_child(polyObj)
		polyObj.polygon = PackedVector2Array(triangle.edges)
		polyObj.material = DebugMaterials[6] 

#region ** MAP GENERATION **

#region ** General **

var allBiomBorders:Dictionary = {}
var nextBiomID:int = 0

func GenerateBasePropertiesOfBiom(initialTriangle:QCTriangle, biomInfo:BiomInfo):
	#[[.0, 1], [.0, .3], [.1, 1]], [10, 18, 3], [false, true, false], 600
	var timestamp = Time.get_ticks_usec()
	var splittedBBGInfo:Array = biomInfo.SplitIndividualGenerationStages()
	var bbgOutp:Dictionary = BBG([initialTriangle], splittedBBGInfo[0], splittedBBGInfo[1], splittedBBGInfo[2], biomInfo.MinBiomSize)
	print("%ms".format([(Time.get_ticks_usec()-timestamp)/1000.], "%"))
	var subdivs:Array[Dictionary] = ConquerGen(bbgOutp, biomInfo.SubdivMinPercentage, biomInfo.SubdivMaxPercentage, biomInfo.SubdivMinDistance)
	print("%ms".format([(Time.get_ticks_usec()-timestamp)/1000.], "%"))
	var freeBorderRegions:Array = RegionBlocking(subdivs, bbgOutp["Entry"], biomInfo.BlockingChance, biomInfo.BlockingBorderMultiplier, biomInfo.BlockingBlockedGroupMultiplier, biomInfo.MinFreeNewBorders)
	print("%ms".format([(Time.get_ticks_usec()-timestamp)/1000.], "%"))
	var expansions:Array[QCTriangle] = GetBiomTriangleExpansionStartPoints(subdivs, freeBorderRegions, bbgOutp["All"])
	print("BiomBasePropertyGen finished in %ms".format([(Time.get_ticks_usec()-timestamp)/1000.], "%"))
	return bbgOutp
	
func LoadBiom():
	pass

#endregion

#region ** QC Management **

var QCs:Dictionary = {}

func get_QC(pPos:Vector2i):
	if QCs.has(pPos): 
		return QCs[pPos]
		
	var tQC = QC.new(pPos, self)
	QCs[pPos] = tQC
	
	return tQC

#endregion

#region ** Expansion Triangle Finder **

func GetBiomTriangleExpansionStartPoints(regions:Array[Dictionary], freeBorders:Array, allBiomTriangles:Dictionary) -> Array[QCTriangle]:
	var possibleExpansions:Array[QCTriangle] = []
	for region in freeBorders:
		var pExp = GetPossibleExpansion(regions[region], allBiomTriangles)
		if pExp != null: possibleExpansions.append(pExp)
		
	return possibleExpansions
		
func GetPossibleExpansion(region:Dictionary, allBiomTriangles:Dictionary) -> QCTriangle:
	var regionAll:Array = region["All"]
	for triangle:QCTriangle in regionAll:
		for neighbor in triangle.getNeighbors():
			if allBiomTriangles.has(neighbor) || allBiomBorders.has(neighbor) || regionAll.has(neighbor): continue
			return neighbor
	return null
		
			

#endregion

#region ** Region Blocking **

func RegionBlocking(regions:Array[Dictionary], startTriangle:QCTriangle, generalBlockingChance:float, borderChanceBoost:float, neighboringBlockerBoost:float, borderSkipCount:int) -> Array:
	var tCountOfBorderRegions:int = 0
	var freeBorderRegionIDs = []
	
	for region in regions:
		var curRegionID:int = region["ID"]			
		var isCurRegionAtBorder:bool = region["IsAtBorder"]
		if curRegionID == 0: 
			if isCurRegionAtBorder: freeBorderRegionIDs.append(curRegionID)
			continue
		if region["All"].has(startTriangle): continue
		
		if isCurRegionAtBorder && tCountOfBorderRegions < borderSkipCount:
			tCountOfBorderRegions += 1
			freeBorderRegionIDs.append(curRegionID)
			continue
		
		var neighboringSubdivIsBlocked:bool = false
		for neighbor in region["Neighbors"]:
			if regions[neighbor]["Blocked"]: neighboringSubdivIsBlocked = true
		
		var randomizor:Vector2i = region["Start"].qc.pos
		var chance:float = generalBlockingChance * (borderChanceBoost if isCurRegionAtBorder else 1) * (neighboringBlockerBoost if neighboringSubdivIsBlocked else 1)
		
		if VRNG.rand(randomizor) < chance && RegionBlockingDijsktraApproval(regions, curRegionID):
			region["Blocked"] = true
		elif isCurRegionAtBorder: freeBorderRegionIDs.append(curRegionID)
		
	return freeBorderRegionIDs

func RegionBlockingDijsktraApproval(regions:Array[Dictionary], newlyBlockedRegion:int) -> bool:	
	
	var tFrontiers = [0]
	var visDict = {0:true}
	while len(tFrontiers) != 0:	
		var nextFrontiers = []
		for regionID in tFrontiers:
			var region:Dictionary = regions[regionID]	
			for neighbor in region["Neighbors"]:
				if visDict.has(neighbor) || regions[neighbor]["Blocked"] || regionID == newlyBlockedRegion: continue
						
				visDict[neighbor] = true
				nextFrontiers.append(neighbor)
		
		tFrontiers = nextFrontiers
		
	for region in regions:
		if !region["Blocked"] && !visDict.has(region["ID"]): 
			return false
		
	return true

#endregion

#region ** Conquer Gen **

func ConquerGen(bbgOutp:Dictionary, minPercentage:float, maxPercentage:float, minDist:int) -> Array[Dictionary]:
	
	var randomizorPos:Vector2i = bbgOutp["Start"].qc.pos
	var all:Dictionary = bbgOutp["All"]
	var border:Dictionary = bbgOutp["Border"]
	var remainings = []
	for t in all: remainings.append(t)
	var sizeOfAll:int = all.size()
	var amount:int = floor(sizeOfAll * VRNG.fRand(minPercentage, maxPercentage, randomizorPos))
	
	var allBlockedTs:Dictionary = {}
	var conquerRegions:Array[Dictionary] = [] #out of { Frontier, All }
	
	for i in range(amount):
		
		if len(remainings) == 0: break
		
		randomizorPos += Vector2i(3, -7)
		var sTriangle:QCTriangle = remainings[VRNG.iRand(0, remainings.size(), randomizorPos)]
		remainings.erase(sTriangle)
		var tFrontier = [sTriangle]
		var fullRegion = [sTriangle]
		var tIsAtBorder = border.has(sTriangle)
		var neighborRegionIDs = {}
		
		for f in range(minDist):
			var nextFrontier = []
			for triangle in tFrontier:
				allBlockedTs[triangle] = i	
				
				for neighbor in triangle.getNeighbors():
					if allBlockedTs.has(neighbor): 
						var tRegID:int = allBlockedTs[neighbor]
						if tRegID != i: neighborRegionIDs[tRegID] = true
						continue
								
					allBlockedTs[neighbor] = i
					nextFrontier.append(neighbor)
					remainings.erase(neighbor)
					
					if border.has(neighbor): tIsAtBorder = true
					
			tFrontier = nextFrontier
			fullRegion += tFrontier
			
		conquerRegions.append({"Frontier":tFrontier, "All":fullRegion, "ID":i, "IsAtBorder":tIsAtBorder, "Start":sTriangle, "Blocked":false, "Neighbors":neighborRegionIDs})
	
	var b:bool = true
	while b:
		b = false
		for region in conquerRegions:
			var curRegionID:int = region["ID"]
			var newFrontier = []
			for triangle:QCTriangle in region["Frontier"]:
				for neighbor in triangle.getNeighbors():
					if allBlockedTs.has(neighbor): 
						var tRegID:int = allBlockedTs[neighbor]
						if tRegID != curRegionID: region["Neighbors"][tRegID] = true
						continue
					if !all.has(neighbor): continue
					allBlockedTs[neighbor] = curRegionID
					
					#print(neighbor.)
					newFrontier.append(neighbor)
					region["All"].append(neighbor)
					b = true
					
					if border.has(neighbor): region["IsAtBorder"] = true
					
			region["Frontier"] = newFrontier
	
	#print("% / %".format([amount, sizeOfAll], "%"))
	
	return conquerRegions

#endregion

#region ** Biom Border Gen **

func BBGDegration(pVal:int, args:Array) -> float:
	if pVal == 0: return args[1]
	return 2. ** (-args[0]*pVal)

func BBG(pStartTriangle:Array, pChanceDegrationFunc:Array, pMaxDepth:Array, pLineExpansion:Array, pMinSize:int) -> Dictionary:
	
	var ccount:int = 1
	
	var visitedTriangles = {}
	var frontierTriangles = pStartTriangle
	var qc_max_x:int = -1_000_000_000
	var qc_min_x:int =  1_000_000_000
	var qc_max_y:int = -1_000_000_000
	var qc_min_y:int =  1_000_000_000
	
	for t in frontierTriangles:
		visitedTriangles[t] = true
	
	for s in len(pChanceDegrationFunc):
		var tDegrationParams:Array = pChanceDegrationFunc[s]
		var lastIterTriangles = []
		var lineExpansion:bool =  pLineExpansion[s]
		var temporaryDisabledTriangles = []
			
		for i in range(pMaxDepth[s]):
			if len(frontierTriangles) == 0: break
			
			var chance:float = BBGDegration(i, tDegrationParams)
			var newFrontierTriangles = []	
			for tTriangle in frontierTriangles:
				var aVec:Vector2i = Vector2i(1,1) if tTriangle.sideO else Vector2i(0,0)
				var firstNeighborSelected:bool = false
				var tTrianglePos:Vector2i = tTriangle.qc.pos 
				
				if VRNG.rand(tTrianglePos * 3 + aVec) < chance:
					var tNeighbors:Array = tTriangle.getNeighbors()
					var tRange = range(3) if VRNG.bRand(tTrianglePos * 4 + aVec) else range(2, -1, -1)
					var tA:int = 0
					for n in tRange:
						var tneighbor:QCTriangle = tNeighbors[n]
						tA += 1
						
						if visitedTriangles.has(tneighbor): continue
						
						if allBiomBorders.has(tneighbor): continue
						
						if firstNeighborSelected && lineExpansion:
							if !visitedTriangles.has(tneighbor.qc.triangle1): temporaryDisabledTriangles.append(tneighbor.qc.triangle1)
							if !visitedTriangles.has(tneighbor.qc.triangle2): temporaryDisabledTriangles.append(tneighbor.qc.triangle2)
							visitedTriangles[tneighbor.qc.triangle1] = true
							visitedTriangles[tneighbor.qc.triangle2] = true
							continue
						
						newFrontierTriangles.append(tneighbor)
						lastIterTriangles.append(tneighbor)
						visitedTriangles[tneighbor] = true
						ccount += 1
						firstNeighborSelected = true
						
						var tPos:Vector2i = tneighbor.qc.pos	
						if tPos.x <= qc_min_x: qc_min_x = tPos.x - 1
						if tPos.y <= qc_min_y: qc_min_y = tPos.y - 1
						if tPos.x >= qc_max_x: qc_max_x = tPos.x + 1
						if tPos.y >= qc_max_y: qc_max_y = tPos.y + 1
				
											
						#var polyObj = PolygonObject.instantiate()
						#add_child(polyObj)
						#polyObj.polygon = PackedVector2Array(tneighbor.edges)
						#polyObj.material = DebugMaterial1 if t.debugDiagonal else DebugMaterial2
						
			frontierTriangles = newFrontierTriangles
		
								
		for tTriangle in temporaryDisabledTriangles:
			visitedTriangles.erase(tTriangle)
		
		temporaryDisabledTriangles = []
		
		frontierTriangles = lastIterTriangles
	
	while len(visitedTriangles) < pMinSize:
		
		if len(frontierTriangles) == 0: break

		var newFrontierTriangles = []	
		for tTriangle in frontierTriangles:
			for neighbor in tTriangle.getNeighbors():
				if visitedTriangles.has(neighbor): continue
				
				if allBiomBorders.has(neighbor): continue
				
				newFrontierTriangles.append(neighbor)
				visitedTriangles[neighbor] = true
					
				var tPos:Vector2i = neighbor.qc.pos	
				if tPos.x <= qc_min_x: qc_min_x = tPos.x - 1
				if tPos.y <= qc_min_y: qc_min_y = tPos.y - 1
				if tPos.x >= qc_max_x: qc_max_x = tPos.x + 1
				if tPos.y >= qc_max_y: qc_max_y = tPos.y + 1
					
			frontierTriangles = newFrontierTriangles
		
	
	var quadLimitingQCs = [
		get_QC(Vector2i(qc_min_x, qc_min_y)), get_QC(Vector2i(qc_max_x, qc_min_y)),
		get_QC(Vector2i(qc_min_x, qc_max_y)), get_QC(Vector2i(qc_max_x, qc_max_y))]
	var borderDijkstraVisDict:Dictionary = {}
	var borderDijkstraFrontiers:Array = [
		quadLimitingQCs[0].triangle1, quadLimitingQCs[0].triangle2,
		quadLimitingQCs[1].triangle1, quadLimitingQCs[1].triangle2,
		quadLimitingQCs[2].triangle1, quadLimitingQCs[2].triangle2,
		quadLimitingQCs[3].triangle1, quadLimitingQCs[3].triangle2]
	var borderTriangles:Dictionary = {}
	var innerTriangles:Dictionary = {}
	
	#print("X from % to %".format([qc_min_x, qc_max_x], "%"))
	#print("Y from % to %".format([qc_min_y, qc_max_y], "%"))
	
	while len(borderDijkstraFrontiers) != 0:	
		var nextFrontiers = []
		for triangle in borderDijkstraFrontiers:
			borderDijkstraVisDict[triangle] = true
			var tNeighbors:Array = triangle.getNeighbors()			
			for neighbor in tNeighbors:
				
				if borderDijkstraVisDict.has(neighbor): continue
				
				if !Vec2iInBox(neighbor.qc.pos, qc_min_x, qc_max_x, qc_min_y, qc_max_y): continue
							
				borderDijkstraVisDict[neighbor] = true
				if visitedTriangles.has(neighbor): 
					borderTriangles[neighbor] = true
					continue
					
				nextFrontiers.append(neighbor)
		
		borderDijkstraFrontiers = nextFrontiers
				
	borderDijkstraFrontiers = []
	var bbgFQCT:QCTriangle = borderTriangles.keys()[0]
	for n in bbgFQCT.getNeighbors():
		if borderDijkstraVisDict.has(n): continue
		borderDijkstraFrontiers.append(n)
		
	var a = 0
		
	while len(borderDijkstraFrontiers) != 0:	
		var nextFrontiers = []
		for triangle in borderDijkstraFrontiers:
			innerTriangles[triangle] = true
			borderDijkstraVisDict[triangle] = true
			var tNeighbors:Array = triangle.getNeighbors()			
			for neighbor in tNeighbors:
				
				if borderDijkstraVisDict.has(neighbor): continue
				
				borderDijkstraVisDict[neighbor] = true
				nextFrontiers.append(neighbor)
		
		borderDijkstraFrontiers = nextFrontiers
		
	var allTriangles:Dictionary = {}
	#if len(visitedTriangles) >= pMinSize:	
	for t in borderTriangles: 
		allTriangles[t] = true
		allBiomBorders[t] = nextBiomID
	for t in innerTriangles: allTriangles[t] = true
	nextBiomID += 1
		
	return {"Start":bbgFQCT, "Border":borderTriangles, "Inner":innerTriangles, "All":allTriangles, "Entry":pStartTriangle[0], "Null":len(visitedTriangles) < pMinSize}
		
func Vec2iInBox(vec:Vector2i, minX:int, maxX:int, minY:int, maxY:int):
	return vec.x >= minX && vec.x <= maxX && vec.y >= minY && vec.y <= maxY
	
	
func VVV(borderTriangleRef:Dictionary, visitedTriangles:Dictionary, prevQCVisited:bool, x:int, y:int, isOImportant:bool, sideState:bool) -> bool:
	var tQC = get_QC(Vector2i(x,y))
	#var relevantTriangle:QCTriangle = tQC.get_verticalTriangleNeighbor(sideState) if isOImportant else tQC.get_horizontalTriangleNeighbor(sideState)
	var b1:bool = visitedTriangles.has(tQC.triangle1) #&& relevantTriangle == tQC.triangle1
	var b2:bool = visitedTriangles.has(tQC.triangle2) #&& relevantTriangle == tQC.triangle2
	if b1 || b2:
		
		if !prevQCVisited:
			if b1: borderTriangleRef[tQC.triangle1] = true
			if b2: borderTriangleRef[tQC.triangle2] = true
			
			var relevantTriangle:QCTriangle = tQC.get_triangleWithO(sideState) if isOImportant else tQC.get_triangleWithL(sideState)
			
			#if !(b1 && relevantTriangle == tQC.triangle1) && !(b2 && relevantTriangle == tQC.triangle2): 
			#	return false
			
			#print(str(relevantTriangle.qc.pos) + "|" + str(tQC.pos))
			
		return b1 && b2
		
	return false

	
func BBGRecursive(pDepth:int, pMaxDepth:int, pChanceAtDepth:Array):
	
	if pDepth == pMaxDepth: return
	
	BBGRecursive(pDepth + 1, pMaxDepth, pChanceAtDepth)

#endregion

#endregion
