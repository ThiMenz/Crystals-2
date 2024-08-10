class_name TranslationCUOWA extends NetworkCUOWA

@export_subgroup("Translation")
@export var syncPosition:bool = true
@export var syncRotation:bool = false
@export var syncScale:bool = false

var obj:Node

func initCUOWA(pObj:Node):
	obj = pObj
	prevState = TranslationCUOWAState.new(obj)
	goalState = TranslationCUOWAState.new(obj)
	var tSize:int = (12 if syncPosition else 0) + (12 if syncRotation else 0) + (12 if syncScale else 0)
	byteSize = tSize
	beginningOfPacket.append(byteSize)
	
func getCUOWA():
	var rArr := PackedByteArray(beginningOfPacket)
	if syncPosition: rArr.append_array(NetworkCUOWA.encodeVec3(obj.position))
	if syncRotation: rArr.append_array(NetworkCUOWA.encodeVec3(obj.rotation))
	if syncScale: rArr.append_array(NetworkCUOWA.encodeVec3(obj.scale))
	return rArr
	
func updateCUOWA(pData:PackedByteArray, pOffset:int): 

	prevState.set_state()
	var curOffset := pOffset
	if syncPosition:
		goalState.position = decodeVec3(pData, curOffset)
		curOffset += 12
	if syncRotation:
		goalState.rotation = decodeVec3(pData, curOffset)
		curOffset += 12
	if syncScale:
		goalState.scale = decodeVec3(pData, curOffset)
		curOffset += 12
		
	lastChangeTime = Main.PROCESS_TIME
	
	
	
func interpolateCUOWA():
	## Not hard capped on 1 - that's the extrapolation
	var delta:float = (Main.PROCESS_TIME - lastChangeTime) / updateInterval
	
	obj.position = Utils.GetPosBetweenTwoVec3s(prevState.position, goalState.position, delta)

	if Main.M.Multiplayer.multiplayer_id != 1:
		print(obj.position)
