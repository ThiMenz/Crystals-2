class_name VRNG

static var vec2iID : int = typeof(Vector2i(0,0))
static var rFloats : Array = []
static var rMasks : Array = []

static var _rng = RandomNumberGenerator.new()

static func set_seed(pSeed:int):
	var rng = RandomNumberGenerator.new()
	rng.set_seed(pSeed)
	_rng.set_seed(pSeed)
	rFloats.resize(65536)
	rMasks += [35246, 47893]
	for i in range(0, 65536): 
		rFloats[i] = rng.randf()

static func bRand(pInput) -> bool:
	return rand(pInput) < .5

static func iRand(from:int, to:int, pInput) -> int:
	return floor(rand(pInput) * (to-from) + from)
	
static func fRand(from:float, to:float, pInput) -> float:
	return rand(pInput) * (to-from) + from

static func rand(pInput) -> float:
	if typeof(pInput) == vec2iID:
		return rFloats[pInput.x ^ (~pInput.y << 3)]
		
	push_error("VRNG does not support this input type")
	return .0
