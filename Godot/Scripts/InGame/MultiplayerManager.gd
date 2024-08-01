class_name MultiplayerManager extends Node

## Multiplayer Concept:
## Address & Port need to get inputted (or some sort of localhost option selected) 
## That Port & Address needs to be globally available (at least through the UDP-protocol)
## optimally using a DDNS and static local network ip config
## If somebody should have security concerns with opening a port:
## They can use some sort of tunneling system (like playit.gg or hamachi)
## however this should result in higher latencies
## Dedicated servers are due to the nature of the terrain loading 
## system currently not really possible -> therefore P2P

var address := "127.0.0.1" ##Temporary Address
var port := 17171 ##Temporary Port
var compressionAlgorithm = ENetConnection.COMPRESS_RANGE_CODER 

var peer = ENetMultiplayerPeer.new()
func _ready():
	Main.M.Multiplayer = self
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)

func peer_connected(id): ## Called From Server & Clients
	print("Player Connected: " + str(id))

func peer_disconnected(id): ## Called From Server & Clients
	print("Player Disconnected: " + str(id))

func connected_to_server(): ## Only from Clients
	print("Connected To Server")

func connection_failed(): ## Only from Clients
	print("Connection Failed")

func createServer(pPort:int):

	port = pPort
	
	var error = peer.create_server(port, 10)
	
	print(str(error))
	
	if (error != OK): print("Creation from server called error: " + str(error))
	
	#peer.host.compress(compressionAlgorithm) ## There are a couple of different compression algorithms
	
	multiplayer.multiplayer_peer = peer
	
func connectToServer(pAddress:String, pPort:int):
	
	address = pAddress
	port = pPort
	
	print(address)
	print(port)
	
	peer.create_client(address, port)
	#peer.host.compress(compressionAlgorithm)
	
	multiplayer.multiplayer_peer = peer


func _on_server_btn_button_down():
	createServer(17171)

func _on_client_btn_button_down():
	connectToServer("within-adventures.gl.at.ply.gg", 19493) # 5.146.64.84 / tlm.mywire.org
