class_name TerrainPixelInfo

## Theoratically only 2x8 bytes (but idk how much gdscript 
## actually needs for this object / the variants)
## Byte-Split => height:4, splatmaps:6, albedo:3, biomDependency:2, additionalInfo:1

var EnPxI1:int # BiomDependency (48-62), Splatmaps (0-47)
var EnPxI2:int # AdditionalInfo (57), Albedo (32-56), Height (0-31)

func _init():
	EnPxI1 = 271789825458176
	EnPxI2 = 0xFFFFFFFF
	
func merge(pxl:TerrainPixelInfo):
	setAlbedo(pxl.getAlbedo())
	if pxl.getIsHole(): setToHole()
	setHeight(pxl.getHeight())
	setSplatmaps(pxl.getSplatmaps())
	forceSetBiomDependency(pxl.getBiomDependency())
		
func setSplatmaps(pSplats:Array[Color]):
	var arr:Array[Array] = []
	for i in 4:
		var tCol:Color = pSplats[i]
		if tCol.r8 != 0: setSplatmap(i * 4, tCol.r8)
		if tCol.g8 != 0: setSplatmap(i * 4 + 1, tCol.g8)
		if tCol.b8 != 0: setSplatmap(i * 4 + 2, tCol.b8)
		if tCol.a8 != 0: setSplatmap(i * 4 + 3, tCol.a8)
			
func setAlbedo(pAlbedo:Color):
	EnPxI2 = (EnPxI2 & 0x1000000FFFFFFFF)    | (maxi(
	(EnPxI2 >> 32) & 255, pAlbedo.r8) << 32) | (maxi(
	(EnPxI2 >> 40) & 255, pAlbedo.g8) << 40) | (maxi(
	(EnPxI2 >> 48) & 255, pAlbedo.b8) << 48)

func setToHole():
	EnPxI2 |= 0x100000000000000
	#EnPxI2 &= 0xFFFFFFFFFFFFFF
	
func setHeight(pHeight:float):
	EnPxI2 = (EnPxI2 & 0x7FFFFFFF00000000) | mini(
		int(pHeight * 524288) + 1073741824, EnPxI2 & 0xFFFFFFFF)
		
func setBiomDependency(pID:int):
	if (EnPxI1 & 0x7FFF000000000000) != 0: return
	EnPxI1 = (EnPxI1 & 0xFFFFFFFFFFFF) | (pID << 48)
	
func forceSetBiomDependency(pID:int):
	EnPxI1 = (EnPxI1 & 0xFFFFFFFFFFFF) | (pID << 48)
	
const splatmapMasks:Array[int] = [0x7FFFFFF0FFFFFF00, 0x7FFFFF0FFFFF00FF, 0x7FFFF0FFFF00FFFF, 0x7FFF0FFF00FFFFFF]
func setSplatmap(pIdx:int, pSplat:int):
	var lowestSplat:int = 256
	var lowestSplatIdx:int = 0
	for i in 4:
		var tV:int = (EnPxI1 >> (i * 8)) & 255
		
		if (((EnPxI1 >> (i*4+32)) & 15) == pIdx):
			lowestSplat = tV
			lowestSplatIdx = i
			break
			
		if lowestSplat > tV:
			lowestSplatIdx = i
			lowestSplat = tV		
	if lowestSplat > pSplat: return
	EnPxI1 = (EnPxI1 & splatmapMasks[lowestSplatIdx]) | (pSplat << (8 * lowestSplatIdx)) | (pIdx << (32 + lowestSplatIdx * 4))
	
func getBiomDependency() -> int:
	return EnPxI1 >> 48
	
func getAlbedo() -> Color:
	return Color8((EnPxI2 >> 32) & 255, (EnPxI2 >> 40) & 255, (EnPxI2 >> 48) & 255)

func getIsHole() -> bool:
	return EnPxI2 & 0x100000000000000

## -1024 > height <= 1024 (1/2048 = 0.00048828125)
func getHeight() -> float:
	return float((EnPxI2 & 0xFFFFFFFF) - 1073741824) / 524288
	
## Even though this looks pretty inefficient:
## -> ~700k/sec should be okayish: *289 = ~0.4ms
## The second one is pretty much equally fast
func getSplatmaps() -> Array[Color]:
	var tArr:Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	tArr[(EnPxI1 >> 32) & 15] = EnPxI1 & 255
	tArr[(EnPxI1 >> 36) & 15] = (EnPxI1 >> 8) & 255
	tArr[(EnPxI1 >> 40) & 15] = (EnPxI1 >> 16) & 255
	tArr[(EnPxI1 >> 44) & 15] = (EnPxI1 >> 24) & 255
	return [
		Color8(tArr[0], tArr[1], tArr[2], tArr[3]), 
		Color8(tArr[4], tArr[5], tArr[6], tArr[7]), 
		Color8(tArr[8], tArr[9], tArr[10], tArr[11]), 
		Color8(tArr[12], tArr[13], tArr[14], tArr[15])
	]

	#var rArr:Array[Color] = [Color(0, 0, 0, 0), Color(0, 0, 0, 0),Color(0, 0, 0, 0), Color(0, 0, 0, 0)]
	#for i in 4:
	#	var pIdx:int = (EnPxI1 >> (32 + 4 * i)) & 15
	#	var v:int = pIdx & 3
	#	if v == 0: rArr[pIdx >> 2].r8 = (EnPxI1 >> (8 * i)) & 255
	#	elif v == 1: rArr[pIdx >> 2].g8 = (EnPxI1 >> (8 * i)) & 255
	#	elif v == 2: rArr[pIdx >> 2].b8 = (EnPxI1 >> (8 * i)) & 255
	#	elif v == 3: rArr[pIdx >> 2].a8 = (EnPxI1 >> (8 * i)) & 255
	#return rArr
