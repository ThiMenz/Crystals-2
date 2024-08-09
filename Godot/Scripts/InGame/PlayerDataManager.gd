class_name PlayerManager

static var playerMultiplayerIDs = {} #string(UserID) : int(ServerID)
static var playerObjects:Dictionary = {} #int(ServerID) : Node

static func get_player(userID:String) -> Dictionary:
	assert(Main.World["Players"].has(userID), "This Player does not exist!")
	return Main.World["Players"][userID]
	
static func get_player_attribute(userID:String, attribute:String):
	var tPlayer := get_player(userID)
	if tPlayer.has(attribute): return tPlayer[attribute]
	return null
	
static func spawn_player(multiplayerID:int) -> Node:
	var playerInst = Main.M.Simulation.PlayerSpwn.instantiate()
	playerInst.name = "Player" + str(multiplayerID)
	Main.M.Simulation.TopDownSceneNode.add_child(playerInst)
	playerInst.set_multiplayer_authority(multiplayerID)
	#playerInst.Synchronizer.set_visibility_for(Main.M.Multiplayer.multiplayer_id, true)
	return playerInst

static func add_player(userID:String):
	if !Main.World.has("Players"): Main.World["Players"] = {}
	if !Main.World["Players"].has(userID): 
		Main.World["Players"][userID] = {}
	
