class_name GameManager extends Node

## Probably should be called "WorldManager" - the casual "GameManager" is the SimulationManager

static var curWorldName:String = ""
static var worlds:Dictionary

static func getInfosFromSceneArgs() -> Dictionary:
	var args := Main.M.SceneArgs
	var infos := {}
	infos["Name"] = args["WorldName"]
	infos["Port"] = args["WorldPort"]
	if args.has("WorldSeed"): infos["Seed"] = args["WorldSeed"]
	return infos

func loadNewGame(pInfos:Dictionary):
	loadGame(initNewGame(pInfos))

func initNewGame(pInfos:Dictionary) -> String:
	randomize()
	var rng := RandomNumberGenerator.new()
	
	## RNG-Seed-Save (If no seed specified; use random seed)
	var rngSeed := rng.randi()
	if pInfos.has("Seed"): rngSeed = pInfos["Seed"]
	
	## Name Creation (Checking if other world with same name already exists)
	var inputName = pInfos["Name"]
	var uniqueName = createUniqueName(inputName)
	worlds[uniqueName] = {
		"Seed" = rngSeed,
		"Port" = pInfos["Port"]
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
	
func loadGame(pWorldName:String):
	curWorldName = pWorldName
	var world:Dictionary = worlds[pWorldName]
	VRNG.set_seed(world["Seed"])
	Main.M.UI.unload()
	Main.M.MainSceneManager.loadScene("Game")
	Main.M.Multiplayer.createServer(world["Port"])
	Main.M.Simulation.beginSimulation()
