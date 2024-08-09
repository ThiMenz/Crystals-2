class_name NetworkCUOWA

## CUOWA = Constantly Updating Object With Authority

static var ALL:Array[Array] = []

var updateRate:int = 3 ## updateRate / 56 = interval in seconds (1 - 112)
var cuowaID:int = 0 ## 0 - 65535
var cuowaPool:int = 0 ## 0 - 255
var beginningOfPacket:PackedByteArray = PackedByteArray()
var hasAuthority:bool = false

func initIDs(pID:int, pPool:int):
	assert(pID >= 0 && pID < 65536 && pPool >= 0 && pPool < 256)
	
	cuowaID = pID
	cuowaPool = pPool
	
	beginningOfPacket.resize(3)
	beginningOfPacket[0] = cuowaPool
	beginningOfPacket.encode_u16(1, cuowaID)
	
	hasAuthority = Main.M.Multiplayer.custom_peer_id == pPool
	
	ALL[updateRate].append(self)
	
func removeCUOWA():
	ALL[updateRate].erase(self)
	
func getCUOWA(): pass
func updateCUOWA(): pass

func decodeVec3(data:PackedByteArray) -> Vector3:
	return Vector3(
		data.decode_float(0),
		data.decode_float(4),
		data.decode_float(8)
		)
	
func encodeVec3(vec:Vector3) -> PackedByteArray:
	var tArr := PackedByteArray()
	tArr.resize(12)
	tArr.encode_float(0, vec.x)
	tArr.encode_float(4, vec.y)
	tArr.encode_float(8, vec.z)
	return tArr
