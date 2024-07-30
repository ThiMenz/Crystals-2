class_name GameManager extends Node

#static var curWorldName:String = ""?
static var worlds:Dictionary = {}

func initNewGame(pInfos:Dictionary):
	randomize()
	var rng := RandomNumberGenerator.new()
	
	## RNG-Seed-Save (If no seed specified; use random seed)
	var rngSeed := rng.randi()
	if pInfos.has("Seed"): rngSeed = pInfos["Seed"]
	
	## Name Creation (Checking if other world with same name already exists)
	var inputName = pInfos["Name"]
	var curName = inputName
	var tSameNameCount := 1
	while worlds.has(curName):
		tSameNameCount += 1
		curName = inputName + str(tSameNameCount)
	
	worlds[curName] = {
		"Seed" = rngSeed
	}
	
func loadGame(pWorldName:String):
	var world:Dictionary = worlds[pWorldName]
	VRNG.set_seed(world["Seed"])
