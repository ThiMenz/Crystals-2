class_name NetworkCUOWA extends Resource

## CUOWA = Constantly Updating Object With Authority
## If the updateRate is equal to zero, it is a one time updated object

## Required variables & methods:
#var cuowa:NetworkCUOWA
#func on_spawn(data:Array): pass INCLUDING initCuowa call
#func on_destroy(data:Array): pass

static var ALL:Dictionary = {} # (int, NetworkCuowa)
static var ALL_ORDERED:Array[Array] = []

@export_subgroup("General")
@export_range(0, 112) var updateRate:int = 3 ## updateRate / 56 = interval in seconds (1 - 112)
var updateInterval:float = .02

var ID:int = 0
var byteSize:int = 0

var beginningOfPacket:PackedByteArray = PackedByteArray()
var hasAuthority:bool = false
var authorityCustomClientID:int = 0

var prevState
var goalState
var lastChangeTime:float

var mainObj:Node

func init(pID:int, pMainObj:Node, pHasAuth:bool):
	ID = pID
	
	mainObj = pMainObj

	beginningOfPacket.resize(3)
	beginningOfPacket[0] = ID & 255
	beginningOfPacket[1] = (ID >> 8) & 255
	beginningOfPacket[2] = (ID >> 16) & 255
	
	hasAuthority = pHasAuth
	authorityCustomClientID = (pID + 1) / 65536
	
	updateInterval = updateRate / 56.
	
	ALL_ORDERED[updateRate].append(self)
	ALL[ID] = self
	
func removeCUOWA(pData:Array):
	mainObj.on_destroy(pData)
	ALL.erase(ID)
	ALL_ORDERED[updateRate].erase(self)
	mainObj.queue_free()
	
func getCUOWA(): pass
func updateCUOWA(pData:PackedByteArray, pOffset:int):
	lastChangeTime = Main.PROCESS_TIME
func interpolateCUOWA(): pass

static func decodeVec3(data:PackedByteArray, offset:int=0) -> Vector3:
	return Vector3(
		data.decode_float(0 + offset),
		data.decode_float(4 + offset),
		data.decode_float(8 + offset)
		)
	
static func encodeVec3(vec:Vector3) -> PackedByteArray:
	var tArr := PackedByteArray()
	tArr.resize(12)
	tArr.encode_float(0, vec.x)
	tArr.encode_float(4, vec.y)
	tArr.encode_float(8, vec.z)
	return tArr
	
static func decodeInt24(data:PackedByteArray, offset:int=0) -> int:
	return data[0] | ((data[1] << 8)) | ((data[2] << 16))
