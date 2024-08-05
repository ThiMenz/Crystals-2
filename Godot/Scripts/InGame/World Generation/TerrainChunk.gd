class_name TerrainChunk

static var spwn:PackedScene
static var spwnParent:Node

var gameInstance:HTerrain
var terrainData:HTerrainData

var realPos:Vector3
var chunkPos:Vector2i
var chunkPosx64:Vector2i

var heightmap: Image
var normalmap: Image
var splatmap1: Image
var splatmap2: Image
var splatmap3: Image
var splatmap4: Image

#var floatHeightmap := PackedFloat32Array.new()
var heightmapShape := HeightMapShape3D.new()

func _init(pPos:Vector2i):
	gameInstance = spwn.instantiate()
	spwnParent.add_child(gameInstance)
	
	terrainData = HTerrainData.new()
	terrainData.resize(65)
	
	heightmapShape.map_depth = 65
	heightmapShape.map_width = 65
	
	gameInstance.set_data(terrainData)
	
	UpdatePosition(pPos)
	
	heightmap = terrainData.get_image(HTerrainData.CHANNEL_HEIGHT)
	normalmap = terrainData.get_image(HTerrainData.CHANNEL_NORMAL)
	splatmap1 = terrainData.get_image(HTerrainData.CHANNEL_SPLAT, 0)
	splatmap2 = terrainData.get_image(HTerrainData.CHANNEL_SPLAT, 1)
	splatmap3 = terrainData.get_image(HTerrainData.CHANNEL_SPLAT, 2)
	splatmap4 = terrainData.get_image(HTerrainData.CHANNEL_SPLAT, 3)
	
func UpdatePosition(pPos:Vector2i):
	chunkPos = pPos
	chunkPosx64 = pPos * 64
	realPos = Vector3(chunkPosx64.x, 0, chunkPosx64.y)
	gameInstance.position = realPos
	
const defaultSplats:Array[Color] = [Color(1, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0)]
	
func SubchunkRendering(subchunkIdx:int):
	var tPos:Vector2i = 16 * Vector2i(subchunkIdx >> 2, subchunkIdx & 3)
	
	const noise_multiplier:float = 2.5
	
	var defaultFNL:FastNoiseLite = MapGen.defaultTerrainFNL
	
	## 17x17 (instead of 16) is due to me being lazy; technically that's
	## only relevant for the few subchunks at a border
	for xi in 17:
		var localX:int = tPos.x + xi
		var x:int = localX + chunkPosx64.x
		for zi in 17:
			var localZ:int = tPos.y + zi
			var z:int = localZ + chunkPosx64.y
			
			var tPxl := TerrainPixelManager.getPixelInfo(Vector2i(x, z))
			var tPxlRight := TerrainPixelManager.getPixelInfo(Vector2i(x + 1, z))
			var tPxlForward := TerrainPixelManager.getPixelInfo(Vector2i(x, z + 1))
			
			var h:float = .0
			var h_right:float = noise_multiplier * (defaultFNL.get_noise_2d(x + 1, z) + 1.) if tPxlRight == null else tPxlRight.getHeight()
			var h_forward:float = noise_multiplier * (defaultFNL.get_noise_2d(x, z + 1) + 1.) if tPxlForward == null else tPxlForward.getHeight()
			var tSplats:Array[Color]
			
			if tPxl == null:
				h = noise_multiplier * (defaultFNL.get_noise_2d(x, z) + 1.)
				tSplats = defaultSplats
			else:
				h = tPxl.getHeight()
				tSplats = tPxl.getSplatmaps()
					
			var normal = Vector3(h - h_right, 1, h_forward - h).normalized()

			heightmap.set_pixel(localX, localZ, Color(h, 0, 0))
			normalmap.set_pixel(localX, localZ, HTerrainData.encode_normal(normal))
			splatmap1.set_pixel(localX, localZ, tSplats[0])
			splatmap2.set_pixel(localX, localZ, tSplats[1])
			splatmap3.set_pixel(localX, localZ, tSplats[2])
			splatmap4.set_pixel(localX, localZ, tSplats[3])
			
		
	# Getting normal by generating extra heights directly from noise,
	# so map borders won't have seams in case you stitch them
	# Generate texture amounts
	#var splat = splatmap1.get_pixel(localX, z)
	#var slope = 4.0 * normal.dot(Vector3.UP) - 2.0
	# Sand on the slopes
	#var sand_amount = clamp(1.0 - slope, 0.0, 1.0)
	# Leaves below sea level
	#var leaves_amount = clamp(0.0 - h, 0.0, 1.0)
	#splat = splat.linear_interpolate(Color(0,1,0,0), sand_amount)
	#splat = splat.linear_interpolate(Color(0,0,1,0), leaves_amount)	
	#var modified_region = Rect2(tPos, Vector2i(17, 17)) #Vector2i(20, 20)
	#terrainData.notify_region_change(modified_region, HTerrainData.CHANNEL_HEIGHT)
	#terrainData.notify_region_change(modified_region, HTerrainData.CHANNEL_NORMAL)
	#terrainData.notify_region_change(modified_region, HTerrainData.CHANNEL_SPLAT)
	
func FullchunkRendering():
	for i in 16: SubchunkRendering(i)
	FinalizeRendering()
	
func FinalizeRendering():
	var modified_region = Rect2(Vector2(), Vector2i(65, 65)) #Vector2i(20, 20)
	terrainData.notify_region_change(modified_region, HTerrainData.CHANNEL_HEIGHT)
	terrainData.notify_region_change(modified_region, HTerrainData.CHANNEL_NORMAL)
	terrainData.notify_region_change(modified_region, HTerrainData.CHANNEL_SPLAT)
	
	heightmapShape.map_data = heightmap.get_data().to_float32_array()
	gameInstance.CustomColliderContainer.set_shape(heightmapShape)
	#gameInstance.update_collider()
	#gameInstance.set_data(terrainData)
