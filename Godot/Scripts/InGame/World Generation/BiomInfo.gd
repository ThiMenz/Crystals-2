class_name BiomInfo extends Resource

@export var ID:int

@export_group("Main Border")
@export var MinBiomSize:int
@export var GenerationStages:Array[BiomGenStateInfo]

@export_group("Subdivisions")
@export var SubdivMinPercentage:float
@export var SubdivMaxPercentage:float
@export var SubdivMinDistance:int

@export_group("Blocking")
@export var BlockingChance:float
@export var BlockingBorderMultiplier:float
@export var BlockingBlockedGroupMultiplier:float
@export var MinFreeNewBorders:int

func _init():
	
	pass

func SplitIndividualGenerationStages() -> Array:
	var rArr:Array = []
	for i in range(BiomGenStateInfo.PropertyCount): rArr.append([])
	for stage in GenerationStages:
		rArr[0].append(stage.ChanceDegrationArgs)
		rArr[1].append(stage.MaxDepth)
		rArr[2].append(stage.IsLineGen)
	return rArr
