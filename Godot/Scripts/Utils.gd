class_name Utils

static func Vec2iInBox(vec:Vector2i, minX:int, maxX:int, minY:int, maxY:int) -> bool:
	return vec.x >= minX && vec.x <= maxX && vec.y >= minY && vec.y <= maxY

static func GetVec2iNeighbors(vec:Vector2i) -> Array[Vector2i]:
	return [vec+Vector2i(1,0), vec-Vector2i(1,0), vec+Vector2i(0,1), vec-Vector2i(0,1)]
