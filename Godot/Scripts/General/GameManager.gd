class_name GameManager extends Node

## Probably should be called "WorldManager" - the casual "GameManager" is the SimulationManager

static var curWorldName:String = ""
static var curWorld:Dictionary = {}
static var worlds:Dictionary

static func deleteGame(pName:String):
	worlds.erase(pName)

static func getInfosFromSceneArgs() -> Dictionary:
	var args := Main.M.SceneArgs
	var infos := {}
	infos["Name"] = args["WorldName"]
	infos["Port"] = args["WorldPort"]
	if args.has("WorldSeed"): infos["Seed"] = args["WorldSeed"]
	if args.has("WorldAddress"): infos["Address"] = args["WorldAddress"]
	return infos

func loadNewGame(pInfos:Dictionary):
	loadGame(initNewGame(pInfos))
	#var tThread := Thread.new()
	#tThread.start(loadGame.bind(initNewGame(pInfos)), Thread.PRIORITY_HIGH)
	#tThread.wait_to_finish()

func initNewGame(pInfos:Dictionary) -> String:
	
	if pInfos.has("Address"): return initNewJoinedGame(pInfos)
	
	randomize()
	var rng := RandomNumberGenerator.new()
	
	## RNG-Seed-Save (If no seed specified; use random seed)
	var rngSeed := rng.randi()
	if pInfos.has("Seed"): rngSeed = pInfos["Seed"]
	
	## Name Creation (Checking if other world with same name already exists)
	var inputName = pInfos["Name"]
	var uniqueName = createUniqueName(inputName)
	worlds[uniqueName] = {
		"Seed": rngSeed,
		"Port": pInfos["Port"]
	}
	
	return uniqueName
	
func initNewJoinedGame(pInfos:Dictionary) -> String:
	
	var inputName = pInfos["Name"]
	var uniqueName = createUniqueName(inputName)
	worlds[uniqueName] = {
		"Address": pInfos["Address"],
		"Port": pInfos["Port"]
	}
	
	return uniqueName

func createUniqueName(pName) -> String:
	var curName = pName
	var tSameNameCount := 1
	while worlds.has(curName):
		tSameNameCount += 1
		curName = pName + str(tSameNameCount)
	return curName
	
func copyGame(pWorldName:String) -> String:
	var tWorld:Dictionary = worlds[pWorldName].duplicate()
	var args := Main.M.SceneArgs
	var tName = createUniqueName(args["WorldName"])
	tWorld["Name"] = tName
	tWorld["Port"] = args["WorldPort"]
	
	worlds[tName] = tWorld
	
	return tName
	
func updateCurWorldDictionary():
	pass
	
func loadGame(pWorldName:String):
	curWorldName = pWorldName
	var world:Dictionary = worlds[pWorldName]
	curWorld = world
	Main.World = world
	
	Main.M.UI.loadScene("LoadIntoWorld")
	Main.M.MainSceneManager.loadScene("Game")
	
	if world.has("Address"): 	
		Main.M.Multiplayer.connectToServer(world["Address"], world["Port"])
	else: 
		Main.M.Multiplayer.createServer(world["Port"])
	
	if !Main.M.Multiplayer.readyToPlay: return
	
	finalizeLoadGame()
	
func finalizeLoadGame():
	Main.M.UI.currentScene.changeStatus("Loading World")
	
	VRNG.set_seed(Main.World["Seed"])
	Main.M.Simulation.beginSimulation()
	
	Main.M.UI.unload()
