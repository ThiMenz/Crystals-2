class_name TerrainChunkManager

const MainLoopChunkCount:int = 64 # 4P, 12V, 20N, 28H => 11(C-Ring)*9(SCU)/50(FPS) = 1,98s

var forceLoadedChunks : Dictionary = {}  #Array[TerrainChunk]
var mainLoopChunks : Array[TerrainChunk] = []
var renderedChunks : Dictionary = {} #(Vec2i:float)

var nextFrameProcessChunk : TerrainChunk = null
var nextFrameProcessChunkIter : int = 0

func UnloadChunks(chunks:Dictionary):
	for i in MainLoopChunkCount:
		var curChunk := mainLoopChunks[i]
		if chunks.has(curChunk.chunkPos): 
			renderedChunks.erase(curChunk.chunkPos)

func FrameProcessAandBRings(ring:Dictionary, returnAfterOneLoad:bool) -> bool:
	var b:bool = false
	for chunkVec in ring:
		if renderedChunks.has(chunkVec): 
			renderedChunks[chunkVec] = SimulationManager.Frame
			continue

		var curLowestFrameChunk:TerrainChunk = getMostIrrelevantLoadedMainLoopChunk()
		renderedChunks.erase(curLowestFrameChunk.chunkPos)
		curLowestFrameChunk.UpdatePosition(chunkVec)	
		renderedChunks[chunkVec] = SimulationManager.Frame
		curLowestFrameChunk.FullchunkRendering()
		
		if returnAfterOneLoad: return true
		b = true
	return b

func FrameProcess(pPlayerPos:Vector3):
	var tVec:Vector2i = GetNearestLeftBottomChunkOrigin(pPlayerPos)
	
	## Really near chunks are required to be loaded; this can cause lags 
	## on really low framerates as soon as the player moves too quickly
	if FrameProcessAandBRings(GetRing(tVec, 1), false): return
		
	## These are chunks which could be in vision and therefore require a
	## higher priority than the following ones
	if FrameProcessAandBRings(GetRing(tVec, 2), true): return
		
	## If all nearby chunks are already loaded, chunks one ring further away
	## will slowly (17 frames per chunk) get prerendered to avoid lag later	
	if nextFrameProcessChunk == null:
		var CRing:Dictionary = GetRing(tVec, 3)
		var nextLoad = null
		for chunkVec in CRing:
			if renderedChunks.has(chunkVec): 
				renderedChunks[chunkVec] = SimulationManager.Frame
				continue
			
			if forceLoadedChunks.has(chunkVec): continue
			
			nextLoad = chunkVec
			
		if nextLoad == null: return
			
		var curLowestFrameChunk:TerrainChunk = getMostIrrelevantLoadedMainLoopChunk()
		
		renderedChunks.erase(curLowestFrameChunk.chunkPos)
		curLowestFrameChunk.UpdatePosition(nextLoad)	
		nextFrameProcessChunk = curLowestFrameChunk
		nextFrameProcessChunkIter = 0
		
	if nextFrameProcessChunk != null:
		if renderedChunks.has(nextFrameProcessChunk.chunkPos): 
			nextFrameProcessChunk = null
			return
		
		if nextFrameProcessChunkIter == 16:
			nextFrameProcessChunk.FinalizeRendering()
			renderedChunks[nextFrameProcessChunk.chunkPos] = SimulationManager.Frame
			nextFrameProcessChunk = null
			return
			
		nextFrameProcessChunk.SubchunkRendering(nextFrameProcessChunkIter)
		#nextFrameProcessChunk.SubchunkRendering(nextFrameProcessChunkIter + 1)
		nextFrameProcessChunkIter += 1

func getMostIrrelevantLoadedMainLoopChunk() -> TerrainChunk:
	var curLowestFrame:int = SimulationManager.Frame + 10
	var curLowestFrameChunk:TerrainChunk = null
	for chunk:TerrainChunk in mainLoopChunks:
		
		if !renderedChunks.has(chunk.chunkPos): return chunk
		
		var tFrame:int = renderedChunks[chunk.chunkPos]
		if tFrame < curLowestFrame:
			curLowestFrame = tFrame
			curLowestFrameChunk = chunk
			
	return curLowestFrameChunk

func InitializeMainLoopChunks():
	for i in MainLoopChunkCount: 
		mainLoopChunks.append(TerrainChunk.new(Vector2i(i+2048,0)))
	
func ForceLoadBiom():
	# Ich muss hier an die schon geladenen Chunks denken
	pass
	

func GetNearestLeftBottomChunkOrigin(pVec:Vector3) -> Vector2i:
	return Vector2i(int(pVec.x) >> 6, int(pVec.z) >> 6) 
	
func GetRings_AB(pNRBCOPos:Vector2i) -> Dictionary:
	var rDict:Dictionary = {}
	for xo in 4:
		var tX:int = pNRBCOPos.x + xo - 3
		for yo in 4:
			rDict[Vector2i(tX, pNRBCOPos.y + yo - 1)] = true
	return rDict

func GetRing(pNRBCOPos:Vector2i, ringIdx:int) -> Dictionary:
	var rDict:Dictionary = {}
	var x1:int = pNRBCOPos.x - ringIdx + 1
	var x2:int = pNRBCOPos.x + ringIdx
	var y1:int = pNRBCOPos.y - ringIdx + 1
	var y2:int = pNRBCOPos.y + ringIdx
	for i in 2 * ringIdx:
		rDict[Vector2i(x1, y1 + i)] = true 
		rDict[Vector2i(x2, y1 + i)] = true 
	for i in 2 * ringIdx - 2:
		rDict[Vector2i(x1 + 1 + i, y1)] = true 
		rDict[Vector2i(x1 + 1 + i, y2)] = true 
	#print(rDict)
	return rDict
