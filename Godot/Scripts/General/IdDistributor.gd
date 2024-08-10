class_name IDDistributor

var _dataDict:Dictionary = {} #(int, var)
var _removedIDs:Array[int] = []
var _curMaxID:int = 0
var _maxID:int = 0
var _minID:int = 0

func _init(min_id:int, max_id:int):
	_curMaxID = min_id - 1
	_maxID = max_id
	_minID = min_id
	
func newID() -> int:
	var l_RIDS := len(_removedIDs)
	if l_RIDS != 0:
		var nID:int = _removedIDs[l_RIDS - 1]
		_removedIDs.remove_at(l_RIDS - 1)
		_dataDict[nID] = null
		return nID
		
	assert(_curMaxID != _maxID, "No more IDs available!")
	
	_curMaxID += 1
	_dataDict[_curMaxID] = null
	return _curMaxID
	
func removeID(pID:int, throwErrorIfNotExistant:bool = true):
	var bIsExi:bool = _dataDict.has(pID)
	if throwErrorIfNotExistant: 
		assert(bIsExi, "Tried to remove unexistant ID!")
	
	if !bIsExi: return
	
	_dataDict.erase(pID)
	_removedIDs.append(pID)
	
func setData(pID:int, pData):
	assert(_dataDict.has(pID), "This ID is not distributed yet!")
	_dataDict[pID] = pData
	
func getData(pID:int) -> Variant:
	assert(_dataDict.has(pID), "This ID is not distributed yet!")
	return _dataDict[pID]
	
func hasID(pID:int) -> bool:
	return _dataDict.has(pID)
	
func isIDPossible(pID:int) -> bool:
	return pID >= _minID && pID <= _maxID
