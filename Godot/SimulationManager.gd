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

static var biomThreadPlayerPositionMutex := Mutex.new()
static var biomThreadPlayerPosition := Vector3(0, 0, 0)
	
var thread := Thread.new()

func _ready():
	
	SaveSystem._load()
	
	Engine.max_fps = 250
	
	var arguments := GetCmdLineArgDict()
	
	var timestamp:float = Time.get_ticks_usec()

	TerrainGenerator.simReady()
	ChunkManager.InitializeMainLoopChunks() # Can take a good while (~1s omh)
	
	print((Time.get_ticks_usec() - timestamp) / 1000.)
	
func GetCmdLineArgDict() -> Dictionary:
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			arguments[argument.lstrip("--")] = ""
	return arguments
	
func _test_thread(pTime, pRngSeed):
	for i in 1: 
		TerrainGenerator.GenerateBiom(pRngSeed) 
		#VRNG.fRand(0, 30, Vector2i(3, 3))
	#TerrainGenerator.GenerateBiom()
	print(">>" + str(Time.get_ticks_usec()-pTime))


static var Frame:int = 0

func _process(delta):
	Frame += 1

	#for i in 100000:
	#	cos(300) + sin(200)
		#TerrainPixelManager.getPixelInfo(Vector2i(3, 3))
	
	
		
	
	if Frame == 1:
		thread.start(_test_thread.bind(Time.get_ticks_usec(), rngSeed))
	
	if biomThreadResultMutex.try_lock():
		for threadResult:Dictionary in TerrainGenerator.biomThreadResults:
			TerrainPixelManager.mergeNewPixels(threadResult["Pixel"])
			ChunkManager.UnloadChunks(threadResult["ChunkUpdates"])
		TerrainGenerator.biomThreadResults.clear()
		biomThreadResultMutex.unlock()
	
	#var timestamp:float = Time.get_ticks_usec()
	ChunkManager.FrameProcess(MainCamera.position)
	#print((Time.get_ticks_usec() - timestamp) / 1000.)
