class_name TerrainPixelManager

static var pixel:Dictionary = {} #(Vec2i, TerrainPixelInfo)

static func getPixelInfo(vec:Vector2i) -> TerrainPixelInfo:
	if pixel.has(vec): return pixel[vec]
	return null

static func mergeNewPixels(newPxl:Dictionary):
	pixel.merge(newPxl, true)
