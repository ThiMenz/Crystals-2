class_name MapGen extends Node

@export var terrainObject:HTerrain
@export var terrainSpwn:PackedScene
@export var TestBiomInfo:BiomInfo
@export var randomizationStrength : Vector2

static var chunkAABB_YValue = -10
static var defaultTerrainFNL:FastNoiseLite = FastNoiseLite.new()

func simReady():
	defaultTerrainFNL.seed = SimulationManager.rngSeed
	defaultTerrainFNL.frequency = .09
	TerrainChunk.spwn = terrainSpwn
	TerrainChunk.spwnParent = self
	
	#threads.resize(2)
	#for i in 2:
	#	var thread = Thread.new()
	#	threads[i] = thread
	#
	#
	#var timestamp = Time.get_ticks_usec()
	#print(timestamp)
	#
	#for i in 2:
	#	threads[i].start(_test_thread.bind(timestamp))
	#	
	#print(Time.get_ticks_usec() - timestamp)
		
	#GenerateBiom()
	
## Load / Save System
## Basic Multiplayer

	
	
## Terrain Update Infos
var biomThreadResults:Array[Dictionary] = [] #{ pixel, requiredChunkUpdates }

## General Biom Infos (Mainly accessed from the Biom-Thread)
var bioms:Dictionary = {} # (int, Dictionary)
var biomSaveInfos:Dictionary = {} # (int, Dictionary)
var biomTicks:Array[int] = []

## Technically no hard-capped threshold (everything up to D=3 will be loaded)
const MAX_LOADED_BIOMS:int = 128

func loadBiomSaveInfosIn(pDict:Dictionary):
	biomSaveInfos = pDict
	
	for biomSave in biomSaveInfos:
		biomTicks.append(0)


var biomThreadTick:int = 0
func BiomThreadFunction():
	
	SimulationManager.biomThreadPlayerPositionMutex.lock()
	var playerPos:Vector3 = SimulationManager.biomThreadPlayerPosition
	SimulationManager.biomThreadPlayerPositionMutex.unlock()
	
	var visitedBiomIDs := {}
	var dijkstraFrontier:Array[int] = []
	var firstID:int = -1
	for biom:Dictionary in biomSaveInfos:
		if biom["Rect"].has_point(playerPos):
			var tID:int = biom["ID"]
			dijkstraFrontier.append(tID)
			visitedBiomIDs[tID] = true
			biomTicks[tID] = biomThreadTick
			if firstID == -1 && !bioms.has(tID): firstID = tID
	
	for i in 2:
		var newDijkstraFrontier:Array[int] = []
		for tBiomID:int in dijkstraFrontier:
			
			var tBiom:Dictionary = biomSaveInfos[tBiomID]
			for neighbor in tBiom["Neighbors"]:
				if visitedBiomIDs.has(neighbor): continue
				visitedBiomIDs[neighbor] = true
				newDijkstraFrontier.append(neighbor)
				biomTicks[neighbor] = biomThreadTick
				if firstID == -1 && !bioms.has(neighbor): firstID = neighbor
				
		dijkstraFrontier = newDijkstraFrontier
	
	while len(bioms) >= MAX_LOADED_BIOMS:
		var unloadID:int = -1
		var lowestTick:int = 999_999_999_999_999
		for biomID in bioms:
			var tTick:int = biomTicks[biomID]
			if biomTicks[biomID] != biomThreadTick && lowestTick > tTick:
				lowestTick = tTick
				unloadID = biomID
				
		if unloadID == -1: break
				
		## UNLOAD Mechanism
		
	if firstID != -1:
		
		## LOAD Mechanism
		pass
			
	
	biomThreadTick += 1
	OS.delay_usec(500) # To ensure that the tick count can't realistically reach 2^63

func LoadBiom():
	
	#Rect2.has_point
	
	pass
	
func GenerateBiom(pRngSeed:int):
	
	var pPixelDict:Dictionary = TerrainPixelManager.pixel.duplicate(true)
	
	var defaultFNL := FastNoiseLite.new()
	defaultFNL.seed = pRngSeed
	defaultFNL.frequency = .09
	
	var timestamp = Time.get_ticks_usec()
	
	var biomDict:Dictionary = GenerateBasePropertiesOfBiom(get_QC(Vector2i(0,0)).triangle1, TestBiomInfo, null)
	var allBaseGridCoords:Dictionary = {}
	
	var pixelUpdates:Dictionary = {}
	var requiredChunkUpdates:Dictionary = {}
	
	var a:int = 0

	timestamp = Time.get_ticks_usec()

	for region in biomDict["Regions"]:
		#print((Time.get_ticks_usec()-timestamp)/1000.)
		#print(len(region["All"]))
		var tRegionBlocked:bool = region["Blocked"]
		if tRegionBlocked: continue
		#if region["Blocked"]: continue
		for triangle:QCTriangle in region["All"]:
			for point:Vector2i in triangle.getInnerBaseGridCoords():
				allBaseGridCoords[point] = tRegionBlocked
				#SetTerrainHeight(point, 0)
	
	#print("!!!")
	#print("Generate Biom finished in %ms".format([(Time.get_ticks_usec()-timestamp)/1000.], "%"))
	
	var biomBorderBaseGridCoords:Array[Vector2i] = []			
	for coord:Vector2i in allBaseGridCoords.duplicate():
		
		# Do smth in terms of inner Biom Gen
		var newPxl := TerrainPixelInfo.new()
		newPxl.setHeight(0)
		newPxl.setSplatmap(1, 255)
		
		#print(newPxl.getHeight())
		
		if pPixelDict.has(coord): newPxl.merge(pPixelDict[coord])
		if pixelUpdates.has(coord): newPxl.merge(pixelUpdates[coord])
		
		#print(newPxl.getHeight())
		pixelUpdates[coord] = newPxl
		
		for neighbor in Utils.GetVec2iNeighbors(coord):
			if !allBaseGridCoords.has(neighbor): 
				biomBorderBaseGridCoords.append(neighbor)
				allBaseGridCoords[neighbor] = true
	
	#var maxHeights : Array[float] = [., 1., 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8]
	var curDijkstraFrontier:Array[Vector2i] = biomBorderBaseGridCoords.duplicate()
	for i in 10:
		var newDijkstraFrontier:Array[Vector2i] = []
		var tMaxHeight:float = float(i) * 1 #maxHeights[i]
		var tTextureBlendOffRegion:int = .44 * float(i) * 255
		var tTextureBlendGround:int = 255 - tTextureBlendOffRegion
		
		for tPos:Vector2i in curDijkstraFrontier:
			#print(defaultFNL.get_noise_2d(tPos.x, tPos.y) + 1.)
			var fnlVal:float = 2.5 * (defaultFNL.get_noise_2d(tPos.x, tPos.y) + 1.)
			var newPxl := TerrainPixelInfo.new()
			newPxl.setHeight(maxf(.2, minf(tMaxHeight, fnlVal))) # maxf(.5, minf(tMaxHeight, fnlVal))
			
			newPxl.setSplatmap(0, 255)
			newPxl.setSplatmap(1, tTextureBlendGround)
			
			if pPixelDict.has(tPos): newPxl.merge(pPixelDict[tPos])
			if pixelUpdates.has(tPos): newPxl.merge(pixelUpdates[tPos])
			pixelUpdates[tPos] = newPxl
			
		if i == 3: break
		
		for tPos:Vector2i in curDijkstraFrontier:
			for neighbor in Utils.GetVec2iNeighbors(tPos):
				if allBaseGridCoords.has(neighbor): continue
				allBaseGridCoords[neighbor] = true
				newDijkstraFrontier.append(neighbor)	
				
		curDijkstraFrontier = newDijkstraFrontier
		
	#print(len(pixelUpdates))
			
	biomDict["AllBaseGridCoords"] = allBaseGridCoords
	biomDict["OuterBaseGridCoords"] = biomBorderBaseGridCoords
	
	#bioms.append(biomDict)
	
	for coord:Vector2i in pixelUpdates.keys():
		for neighbor:Vector2i in Utils.GetVec2iNeighbors(Vector2i(coord.x >> 6, coord.y >> 6)):
			requiredChunkUpdates[neighbor] = true
			
	#a = 0
	#for i in 1000000:
	#	a += 1
	#	pDict.has(Vector2i(3, 3))
			
	#print(a)
	#print(pDict)
	
	print("Generate Biom finished in %ms".format([(Time.get_ticks_usec()-timestamp)/1000.], "%"))
	
	SimulationManager.biomThreadResultMutex.lock()
	biomThreadResults.append({"Pixel":pixelUpdates, "ChunkUpdates":requiredChunkUpdates})
	SimulationManager.biomThreadResultMutex.unlock()

var allBiomBorders:Dictionary = {}
var nextBiomID:int = 0

func LoadBBG(pData:Dictionary):
	var allTriangles:Dictionary = pData["Border"]
	var curDijkstraFrontier:Array[Vector2i] = [pData["RandomMid"]]
	while len(curDijkstraFrontier) != 0:
		var newDijkstraFrontier:Array[Vector2i] = []
		
		for tPos:Vector2i in curDijkstraFrontier:
			for neighbor in Utils.GetVec2iNeighbors(tPos):
				if allTriangles.has(neighbor): continue
				allTriangles[neighbor] = true
				newDijkstraFrontier.append(neighbor)	
				
		curDijkstraFrontier = newDijkstraFrontier

func GenerateBasePropertiesOfBiom(initialTriangle:QCTriangle, biomInfo:BiomInfo, saveExpansions) -> Dictionary:
	var timestamp = Time.get_ticks_usec()
	
	# Will be saved after first generation process
	var splittedBBGInfo:Array = biomInfo.SplitIndividualGenerationStages()
	var bbgOutp:Dictionary = BBG([initialTriangle], splittedBBGInfo[0], splittedBBGInfo[1], splittedBBGInfo[2], biomInfo.MinBiomSize)
	
	# Can be splitted (otherwise 6ms here)
	var subdivs:Array[Dictionary] = ConquerGen(bbgOutp, biomInfo.SubdivMinPercentage, biomInfo.SubdivMaxPercentage, biomInfo.SubdivMinDistance)
	
	# With around .3ms only needs singular frame
	var freeBorderRegions:Array = RegionBlocking(subdivs, bbgOutp["Entry"], biomInfo.BlockingChance, biomInfo.BlockingBorderMultiplier, biomInfo.BlockingBlockedGroupMultiplier, biomInfo.MinFreeNewBorders)
	
	# Will also be saved
	var t = Time.get_ticks_usec()
	var expansions:Array[QCTriangle] = GetBiomTriangleExpansionStartPoints(subdivs, freeBorderRegions, bbgOutp["All"]) if saveExpansions == null else saveExpansions
	print(">J>" + str(Time.get_ticks_usec() - t))
	#print("BiomBasePropertyGen finished in %ms".format([(Time.get_ticks_usec()-timestamp)/1000.], "%"))
	
	return {"Regions":subdivs, "Expansions":expansions, "BBGDict": bbgOutp}
	
func EmbellishBiom(biomDict:Dictionary):
	var timestamp = Time.get_ticks_usec()
	
	print("EmbellishBiom finished in %ms".format([(Time.get_ticks_usec()-timestamp)/1000.], "%"))

#region ** QC Management **

var QCs:Dictionary = {}

func get_QC(pPos:Vector2i):
	if QCs.has(pPos): 
		return QCs[pPos]
		
	var tQC = QC.new(pPos, self)
	QCs[pPos] = tQC
	
	return tQC

#endregion

#region | Biom Shape Generation |

#region ** Expansion Triangle Finder **

func GetBiomTriangleExpansionStartPoints(regions:Array[Dictionary], freeBorders:Array, allBiomTriangles:Dictionary) -> Array[QCTriangle]:
	var possibleExpansions:Array[QCTriangle] = []		
	var tDijkstraDict:Dictionary = {}
	
	const MIN_DIJKSTRA_COUNT_FOR_EXP = 800
	
	for region in freeBorders:
		var pExp = GetPossibleExpansion(regions[region], allBiomTriangles)
		var tCount:int = 0
		if pExp != null: 
			var curDijkstraFrontier:Array[QCTriangle] = [pExp]
			while len(curDijkstraFrontier) != 0 && tCount < MIN_DIJKSTRA_COUNT_FOR_EXP:
				var newDijkstraFrontier:Array[QCTriangle] = []
				for triangle:QCTriangle in curDijkstraFrontier:				
					tCount += 1
					for neighbor:QCTriangle in triangle.getNeighbors():
						if allBiomTriangles.has(neighbor) || tDijkstraDict.has(neighbor): continue
						tDijkstraDict[neighbor] = true
						newDijkstraFrontier.append(neighbor)	
				curDijkstraFrontier = newDijkstraFrontier
			
			if tCount >= MIN_DIJKSTRA_COUNT_FOR_EXP: 
				possibleExpansions.append(pExp)
		
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
	
	var timestamp:float = Time.get_ticks_usec()
	
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
	
		#print(">>")
		#print((Time.get_ticks_usec() - timestamp) / 1000.)
		timestamp = Time.get_ticks_usec()
	
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
			
		#print(">>>")
		#print((Time.get_ticks_usec() - timestamp) / 1000.)
		timestamp = Time.get_ticks_usec()
	
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
		var tPos:Vector2i = t.qc.pos	
		if tPos.x <= qc_min_x: qc_min_x = tPos.x - 1
		if tPos.y <= qc_min_y: qc_min_y = tPos.y - 1
		if tPos.x >= qc_max_x: qc_max_x = tPos.x + 1
		if tPos.y >= qc_max_y: qc_max_y = tPos.y + 1
	
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
				
				if !Utils.Vec2iInBox(neighbor.qc.pos, qc_min_x, qc_max_x, qc_min_y, qc_max_y): continue
							
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
	for t:QCTriangle in borderTriangles: 
		#print(t.qc.pos)
		allTriangles[t] = true
		allBiomBorders[t] = nextBiomID
	for t in innerTriangles: allTriangles[t] = true
	nextBiomID += 1
		
	return {"Start":bbgFQCT, "Border":borderTriangles, "Inner":innerTriangles, "All":allTriangles, "Entry":pStartTriangle[0], "Null":len(visitedTriangles) < pMinSize}

#endregion

#endregion
