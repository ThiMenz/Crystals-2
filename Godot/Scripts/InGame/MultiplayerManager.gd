class_name MultiplayerManager extends Node

## Multiplayer Concept:
## Address & Port need to get inputted (or some sort of localhost option selected) 
## That Port & Address needs to be globally available (UDP & TCP-protocol)
## optimally using a DDNS and static local network ip config
## If somebody should have security concerns with opening a port:
## They can use some sort of tunneling system (like playit.gg or hamachi)
## however this should result in higher latencies
## Dedicated servers are due to the nature of the terrain loading 
## system currently not possible -> therefore P2P

## TODO
## 3. Exceptions don't cause more ones (regarding the Multiplayer Client / Server Creation)
## Mutliplayer Node does not exist error :(

##Temporary Address & Port
var address := "127.0.0.1"
var port := 17171

func _ready():
	Main.M.Multiplayer = self
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.server_disconnected.connect(server_disconnected)
	
	var a := 0
	for tName:String in spawnDict:
		var tObj:PackedScene = spawnDict[tName]
		spawnableObjs.append(tObj)
		runtimeSpawnDict[tName] = a
		a += 1

## besides from syncing the data when loading in; this should be the correct choice
var compressionAlgorithm = ENetConnection.COMPRESS_RANGE_CODER

var peer := ENetMultiplayerPeer.new()
var multiplayer_id = 1
var custom_peer_id = 0
var customClientIDDistributor := IDDistributor.new(0, 9)
var custom_id_dict:Dictionary = {} #(int(MultID), int(CustomID))
var customIDsToMultIDsDict:Dictionary = {} #(int(CustomID), int(MultID))
var physic_times:Dictionary = {} #(int(mult_id), float)
var localNetworkFrame:int = 0

var readyToPlay := false

## These objects need the cuowa-variable as well as the on_spawn and on_destroy methods
@export var spawnDict:Dictionary # (String, PackedScene)

var runtimeSpawnDict:Dictionary # (String, int)
var spawnableObjs:Array[PackedScene] = []
var delayedClientJoinSpawnObjs:Dictionary = {} # (int(NetID), Array[int(SpawnID), Array])

var localAuthorityObjectIDs := IDDistributor.new(0, 65535)

func networkSpawn(pInstName:String, pAdditionalData:Array=[], delayedClientJoinSpawn:bool = false):
	assert(spawnDict.has(pInstName), "Tried to spawn object with unknown name!")
	
	var tNetworkID:int = localAuthorityObjectIDs.newID()
	var tSpawnID:int = runtimeSpawnDict[pInstName]
	
	if delayedClientJoinSpawn: 
		delayedClientJoinSpawnObjs[tNetworkID] = [tSpawnID, pAdditionalData]
	
	spawn.rpc(tSpawnID, tNetworkID, pAdditionalData)
	
func networkDestroy(pLocalInst, pDestrData:Array=[]):
	destroy.rpc(pLocalInst.cuowa.ID, pDestrData)
	
## NOTE since spawns will not happen as frequently as synchronizations
## I am fine with using the build in serialisation methods, which should
## result in slightly more network bandwidth

var lastSpawnedInstance:Node
@rpc("any_peer", "call_local", "reliable")
func spawn(pSpawnID:int, pNetworkID:int, pInstData:Array=[]):
	var tInstance = spawnableObjs[pSpawnID].instantiate()
	var tHasAuthority = localAuthorityObjectIDs.isIDPossible(pNetworkID)
	tInstance.cuowa = tInstance.cuowa.duplicate()
	tInstance.cuowa.init(pNetworkID, tInstance, tHasAuthority)
	if tHasAuthority: tInstance.set_multiplayer_authority(multiplayer_id)
	lastSpawnedInstance = tInstance
	
	tInstance.on_spawn(pInstData)

@rpc("any_peer", "call_local", "reliable")
func destroy(pNetworkID:int, pDestrData:Array=[]):
	if !NetworkCUOWA.ALL.has(pNetworkID): return
	var netCuowa:NetworkCUOWA = NetworkCUOWA.ALL[pNetworkID]
	delayedClientJoinSpawnObjs.erase(pNetworkID)
	localAuthorityObjectIDs.removeID(pNetworkID, false)
	netCuowa.removeCUOWA(pDestrData)

func visualNetworkProcess():
	for cuowa:NetworkCUOWA in NetworkCUOWA.ALL.values():
		if cuowa.hasAuthority: continue
		cuowa.interpolateCUOWA()

var cuowaRange:Array = range(1, 113)
func networkFrameProcess():
	localNetworkFrame += 1
	
	var thisFramePacket := PackedByteArray()
	for i in cuowaRange:
		if localNetworkFrame % i == 0: 
			for cuowa:NetworkCUOWA in NetworkCUOWA.ALL_ORDERED[i]:
				#multiplayer_print("Auth " + str(cuowa.hasAuthority))
				if cuowa.hasAuthority: 
					thisFramePacket.append_array(cuowa.getCUOWA())
					
	#multiplayer_print("Send Packet of size " + str(len(thisFramePacket)))
		
	send_packet.rpc(multiplayer_id, Main.PHYSICS_TIME, thisFramePacket)
	
@rpc("any_peer", "unreliable_ordered", "call_remote")
func send_packet(multiplayerID:int, authorityTime:float, data:PackedByteArray):
	physic_times[multiplayerID] = authorityTime
	
	#multiplayer_print("Received Packet of size " + str(len(data)))
	
	var dataPointer:int = 0
	var dataLen := len(data)
	while dataPointer < dataLen:
		var netID:int = NetworkCUOWA.decodeInt24(data, dataPointer) 
		var cuowaLen:int = data[dataPointer + 3]
		dataPointer += 4
		
		if !NetworkCUOWA.ALL.has(netID): ##Object not locally available
			dataPointer += cuowaLen
			continue
			
		NetworkCUOWA.ALL[netID].updateCUOWA(data, dataPointer)
		
		dataPointer += cuowaLen

	
func peer_connected(id): ## Called at Server & Clients
	multiplayer_print("Player Connected: " + str(id))
	if multiplayer_id == 1:
		var tNID:int = customClientIDDistributor.newID()
		custom_id_dict[id] = tNID
		customIDsToMultIDsDict[tNID] = id
		setCustomPeerIDs.rpc(custom_id_dict, customIDsToMultIDsDict)
		
	## Inform the newly connected peer about relevant objects to spawn
	for netID:int in delayedClientJoinSpawnObjs:
		var tParams:Array = delayedClientJoinSpawnObjs[netID]
		spawn.rpc_id(id, tParams[0], netID, tParams[1])
		
	#PlayerManager.spawn_player(id)

func peer_disconnected(id): ## Called at Server & Clients
	
	var tCustomClientID:int = custom_id_dict[id]	
	
	if multiplayer_id == 1:
		customClientIDDistributor.removeID(tCustomClientID)
	
	## Destroy all network objects which got instantiated from the now disconnected peer 
	for pObjID:int in NetworkCUOWA.ALL:
		var netC:NetworkCUOWA = NetworkCUOWA.ALL[pObjID]
		if netC.authorityCustomClientID == tCustomClientID:
			destroy(pObjID)
		
	multiplayer_print("Player Disconnected: " + str(id))

func connected_to_server(): ## Only from Clients
	multiplayer_print("Connected To Server")
	Main.M.UI.currentScene.changeStatus("Fetching Server Data")
	
	joined_game()
	
	## Fetch World Data from Server
	var curBiomCount := 0
	if Main.World.has("Bioms"): curBiomCount = len(Main.World["Bioms"])
	fetch_world_data.rpc_id(1, multiplayer_id, curBiomCount)

func connection_failed(): ## Only from Clients
	multiplayer_print("Connection Failed")

func server_disconnected(): ## Only from Clients
	multiplayer_print("Server Disconnected")
	
func joined_game(): ## equivalent to connected_to_server, but server calls it aswell
	add_player_.rpc(Main.USER_ID, multiplayer_id)
	
## NOTE func_ is just the non-static version of a function (so that they can be rpc'ed)
	
var localPlayerSpawned := false
	
@rpc("reliable", "authority", "call_local")
func setCustomPeerIDs(pIDs:Dictionary, pRevDict:Dictionary):
	custom_id_dict = pIDs
	custom_peer_id = custom_id_dict[multiplayer_id]
	customIDsToMultIDsDict = pRevDict
	localAuthorityObjectIDs = IDDistributor.new(custom_peer_id * 65536, custom_peer_id * 65536 + 65535)
	multiplayer_print("PeerID: " + str(custom_peer_id))
	
	if !localPlayerSpawned: 	
		networkSpawn("Player", [], true)
		Main.M.Simulation.LocalTDPlayerNode = lastSpawnedInstance
		localPlayerSpawned = true
	
@rpc("reliable", "authority", "call_remote")
func kick():
	peer.close()
	
@rpc("reliable", "any_peer", "call_local")
func add_player_(userID:String, multiplayerID:int):
	if PlayerManager.has_player(userID):	
		if multiplayer_id == 1:
			kick.rpc_id(multiplayerID)
		return
		
	PlayerManager.add_player(userID, multiplayerID)
	
@rpc("reliable", "any_peer", "call_remote")
func fetch_world_data(multID:int, curBiomCount:int):
	multiplayer_print(curBiomCount)
	var tWorld:Dictionary = Main.World.duplicate(false)
	tWorld.erase("Bioms")
	tWorld.erase("Port")
	tWorld.erase("Name")

	var tNewBiomArr:Array = []
	if Main.World.has("Bioms"):
		var tBioms:Dictionary = Main.World["Bioms"]
		for biomID:int in tBioms:
			if biomID < curBiomCount: continue
			tNewBiomArr.append(tBioms[biomID])
			
	send_world_data.rpc_id(multID, tWorld, tNewBiomArr)
	
@rpc("reliable", "authority", "call_remote")
func send_world_data(dataWithoutBioms:Dictionary, newBioms:Array):
	multiplayer_print(dataWithoutBioms)
	
	## Set data
	Main.World.merge(dataWithoutBioms, true)
	if !Main.World.has("Bioms"): Main.World["Bioms"] = {}
	var a:int = 0
	for biom in newBioms:
		Main.World["Bioms"][a] = biom
		a += 1
		
	readyToPlay = true
	Main.M.Game_Manager.finalizeLoadGame()
	
func multiplayer_print(str):
	print("[%] ".format([multiplayer_id], "%") + str(str))

func createServer(pPort:int):
	Main.M.UI.currentScene.changeStatus("Creating Server")
	
	port = pPort
	
	var error = peer.create_server(port, 10)
	
	if (error != OK): 
		print("Creation from server called error: " + str(error))
		Main.M.UI.currentScene.changeStatus("Failed to create server")
		return
	
	print("Successfully created server :)")
		
	custom_peer_id = customClientIDDistributor.newID()
	setCustomPeerIDs({1:0}, {0:1})
	peer.host.compress(compressionAlgorithm)
	multiplayer.multiplayer_peer = peer
	
	joined_game()
	
	readyToPlay = true
	
func connectToServer(pAddress:String, pPort:int):
	Main.M.UI.currentScene.changeStatus("Connecting to Server")
	address = pAddress
	port = pPort

	var err = peer.create_client(address, port)
	
	if err != OK:
		Main.M.UI.currentScene.changeStatus("Failed to connect")
		return
	
	peer.host.compress(compressionAlgorithm)
	multiplayer.multiplayer_peer = peer
	multiplayer_id = multiplayer.get_unique_id()
