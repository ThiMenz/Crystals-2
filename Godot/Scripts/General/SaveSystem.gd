class_name SaveSystem extends Node

static var autoSaveIntervalTime:float = 60.0 
static var data:Dictionary = {}

const CRYPT_KEY := 1_102_123_328 

var lastAutosave = 10.0 # First 10 seconds no autosave
func _process(delta):
	pass
	
const FILE_DIR := "user://TLM"
const FILE_NAME := "Crystals"
static var FILE_PATH := "%/%.tlm".format([FILE_DIR, FILE_NAME], "%")

static func D(pKey):
	if data.has(pKey): return data[pKey]
	return null

static func _save():
	if !DirAccess.dir_exists_absolute(FILE_DIR): DirAccess.make_dir_absolute(FILE_DIR)
	
	var file = FileAccess.open(FILE_PATH, FileAccess.WRITE)
	
	for tByte in EncryptArray(var_to_bytes_with_objects(data), CRYPT_KEY):
		file.store_8(tByte)
		
	file.close()
	
static func _load():
	if !FileAccess.file_exists(FILE_PATH): return
	var file = FileAccess.get_file_as_bytes(FILE_PATH)
	data = bytes_to_var_with_objects(EncryptArray(file, CRYPT_KEY))
	
static func EncryptArray(pArr: PackedByteArray, pToken: int) -> PackedByteArray:
	var rArr: PackedByteArray
	var cc: int = 0
	
	for tByte in pArr:
		rArr.append(EncryptByte(tByte, pToken, cc))
		cc += 1
	
	return rArr
	
## 2,5 Mio/sec omh
static func EncryptByte(pByte: int, pToken: int, pPos: int) -> int:
	return (pByte ^ (pToken >> int(10. * sin(pPos) + 10.))) & 255
