class_name Utils

static func CreateWorldList(worldElmt, worldVBoxContainer):
	var worlds = SaveSystem.D("Worlds")
	if worlds != null:
		for worldName:String in worlds:
			var elmt:WorldSelectionElement = worldElmt.instantiate()
			worldVBoxContainer.add_child(elmt)
			elmt.worldName = worldName
			elmt.update()

static func Vec2iInBox(vec:Vector2i, minX:int, maxX:int, minY:int, maxY:int) -> bool:
	return vec.x >= minX && vec.x <= maxX && vec.y >= minY && vec.y <= maxY

static func GetVec2iNeighbors(vec:Vector2i) -> Array[Vector2i]:
	return [vec+Vector2i(1,0), vec-Vector2i(1,0), vec+Vector2i(0,1), vec-Vector2i(0,1)]

static func Vec2iTriangleSign(p1:Vector2i, p2:Vector2i, p3:Vector2i) -> float:
	return (p1.x-p3.x) * (p2.y-p3.y) - (p2.x-p3.x) * (p1.y-p3.y)

static func Vec2InTriangle(vec:Vector2, p0:Vector2, p1:Vector2, p2:Vector2) -> bool:
	var dX = vec.x-p2.x
	var dY = vec.y-p2.y
	var dX21 = p2.x-p1.x
	var dY12 = p1.y-p2.y
	var D = dY12*(p0.x-p2.x) + dX21*(p0.y-p2.y)
	var s = dY12*dX + dX21*dY
	var t = (p2.y-p0.y)*dX + (p0.x-p2.x)*dY
	if D < 0: return s <= 0 && t <= 0 && s + t >= D
	return s >= 0 && t >= 0 && s+t <= D
