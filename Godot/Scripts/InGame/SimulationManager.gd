class_name SimulationManager extends Node

## TODO PERFORMANCE GOALS:
## The game should be playable on hardware which is 5 times slower than mine
## I consider playable as: >50FPS, RAM usage <4GiB & Load-Time <15s 
## NOTE omh = On my Hardware (most relevant specs: RTX 3060TI, i11700k, 16GB RAM)

## The Chunk-System should only be tested on hard-capped 50 fps due to Subchunk-Preloading
## TODO Improvement to the B-Ring Loading: No FullChunkRender, probably smth like a quarter

@export var MainCamera:Camera3D
@export var TerrainGenerator:MapGen

static var ChunkManager:TerrainChunkManager = TerrainChunkManager.new()

static var isServerBuild := false

static var rngSeed := 0
static var biomThreadResultMutex := Mutex.new()
static var biomThreadUNLOADResultMutex := Mutex.new()

static var biomThreadPlayerPositionMutex := Mutex.new()
static var biomThreadPlayerPosition := Vector3(0, 0, 0)

static var inPlatformingMode := false
	
var simulationBegan := false
var thread := Thread.new()

func _ready():
	Main.M.Simulation = self
	
func beginSimulation():
	var timestamp:float = Time.get_ticks_usec()

	TerrainGenerator.Reset()
	TerrainGenerator.loadBiomSaveInfosIn(Main.M.Game_Manager.curWorld)
	TerrainGenerator.simReady()
	ChunkManager.InitializeMainLoopChunks() # Can take a good while (~1s omh)
	
	## Generating the first Biom (on the main thread), if the world is new
	if len(Main.M.Game_Manager.curWorld["Bioms"]) == 0:
		TerrainGenerator.BiomInitialisation(TerrainGenerator.get_QC(Vector2i(0,0)).triangle1)
		
	print((Time.get_ticks_usec() - timestamp) / 1000.)
	simulationBegan = true

static var Frame:int = 0

func _process(delta):
	
	if !simulationBegan: return
	Frame += 1
	
	mainThreadTerrainManagement() ## I'm concerned with moving it to only nonPlatformingMode!
	
	if inPlatformingMode:
		return
	else:
		ChunkManager.FrameProcess(MainCamera.position)
		
func mainThreadTerrainManagement():
	
	## Starting the Biom Management Thread
	if Frame == 1: thread.start(TerrainGenerator.BiomThreadFunction)
		
	## Updating the Terrain Pixels and their chunks as soon as the BiomThread
	## finished one Biom-Load-Operation
	if biomThreadResultMutex.try_lock():
		for threadResult:Dictionary in TerrainGenerator.biomThreadResults:
			TerrainPixelManager.mergeNewPixels(threadResult["Pixel"])
			ChunkManager.UnloadChunks(threadResult["ChunkUpdates"])
		TerrainGenerator.biomThreadResults.clear()
		biomThreadResultMutex.unlock()
		
	## Omh 50k dictionary erase calls (with actually removing the items) take 3.5ms
	## since bioms should never have even half of this size, its fine :)
	if biomThreadUNLOADResultMutex.try_lock():
		for tPos:Vector2i in TerrainGenerator.biomThreadUNLOADResults:
			TerrainPixelManager.pixel.erase(tPos)
		TerrainGenerator.biomThreadUNLOADResults.clear()
		biomThreadUNLOADResultMutex.unlock()
	
