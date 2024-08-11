class_name PlayerManager

static var playerMultiplayerIDs := {} #string(UserID) : int(ServerID)
static var playerUserIDs := {} #int(MultiplayerID) : string(UserID)
static var playerObjects := {}

static func get_player(userID:String) -> Dictionary:
	assert(Main.World["Players"].has(userID), "This Player does not exist!")
	return Main.World["Players"][userID]
	
static func get_player_attribute(userID:String, attribute:String):
	var tPlayer := get_player(userID)
	if tPlayer.has(attribute): return tPlayer[attribute]
	return null

static func has_player(userID:String) -> bool:
	return playerMultiplayerIDs.has(userID)

static func add_player(userID:String, multID:int):
	playerUserIDs[multID] = userID
	playerMultiplayerIDs[userID] = multID
	if !Main.World.has("Players"): Main.World["Players"] = {}
	if !Main.World["Players"].has(userID): 
		Main.World["Players"][userID] = {}
	
static func update_player_storages():
	var localPeerID:int = Main.M.Multiplayer.custom_peer_id
	for customClientID:int in playerObjects:
		var multID:int = Main.M.Multiplayer.customIDsToMultIDsDict[customClientID]
		
		if !playerUserIDs.has(multID): continue
		
		var userID:String = playerUserIDs[multID]
		var playerDict:Dictionary = get_player(userID)
		
		if customClientID == localPeerID: 
			playerDict["Pos"] = playerObjects[customClientID].position
			continue
		
		playerDict["Pos"] = playerObjects[customClientID].cuowa.goalState.position
		
	
