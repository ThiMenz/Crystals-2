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
## 1. Diconnect Management
## 2. CONSISTENT Snyc System (but at the same time smooth for the clients)
## -> Anti Cheat or so is NOT relevant (replay files should be evidence enough)
## 3. Exceptions don't cause more ones (regarding the Multiplayer Client / Server Creation)

##Temporary Address & Port
var address := "127.0.0.1"
var port := 17171

## besides from syncing the data when loading in; this should be the correct choice
var compressionAlgorithm = ENetConnection.COMPRESS_RANGE_CODER

var peer := ENetMultiplayerPeer.new()
var multiplayer_id = 1
var custom_peer_id = 0
var customClientIDDistributor := IDDistributor.new(0, 9)
var custom_id_dict:Dictionary = {} #(int, int)
var physic_times:Dictionary = {} #(int(mult_id), float)
var localNetworkFrame:int = 0

var readyToPlay := false

func _ready():
	Main.M.Multiplayer = self
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.server_disconnected.connect(server_disconnected)

func networkFrameProcess():
	localNetworkFrame += 1
	
	## Packets contain constantly updating variables which have a clear authority 
	send_packet.rpc(multiplayer_id, Main.PHYSICS_TIME, PackedByteArray())
	
@rpc("any_peer", "unreliable_ordered", "call_remote")
func send_packet(multiplayerID:int, authorityTime:float, data:PackedByteArray):
	physic_times[multiplayerID] = authorityTime
	
	multiplayer_print(authorityTime)

func peer_connected(id): ## Called at Server & Clients
	multiplayer_print("Player Connected: " + str(id))
	if multiplayer_id == 1:
		var tNID:int = customClientIDDistributor.newID()
		custom_id_dict[id] = tNID
		setCustomPeerIDs.rpc(custom_id_dict)
		
	PlayerManager.spawn_player(id)

func peer_disconnected(id): ## Called at Server & Clients
	if multiplayer_id == 1:
		customClientIDDistributor.removeID(custom_id_dict[id])
	multiplayer_print("Player Disconnected: " + str(id))

func connected_to_server(): ## Only from Clients
	multiplayer_print("Connected To Server")
	Main.M.UI.currentScene.changeStatus("Fetching Server Data")
	
	add_player_.rpc(Main.USER_ID)
	
	## Fetch World Data from Server
	var curBiomCount := 0
	if Main.World.has("Bioms"): curBiomCount = len(Main.World["Bioms"])
	fetch_world_data.rpc_id(1, multiplayer_id, curBiomCount)

func connection_failed(): ## Only from Clients
	multiplayer_print("Connection Failed")

func server_disconnected(): ## Only from Clients
	multiplayer_print("Server Disconnected")
	
##func_ is just the non-static version of a function (so that they can be rpc'ed)
	
@rpc("reliable", "authority", "call_local")
func setCustomPeerIDs(pIDs:Dictionary):
	custom_id_dict = pIDs
	custom_peer_id = custom_id_dict[multiplayer_id]
	multiplayer_print("PeerID: " + str(custom_peer_id))
	
@rpc("reliable", "any_peer", "call_local")
func add_player_(userID:String):
	PlayerManager.add_player(userID)
	
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
	custom_id_dict = {1:0}
	PlayerManager.add_player(Main.USER_ID)
	peer.host.compress(compressionAlgorithm)
	multiplayer.multiplayer_peer = peer
	
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
