class_name AttackBase extends SimulationObject

@export var playerDmg:AttackInfo
@export var enemyDmg:AttackInfo
@export var buildingDmg:AttackInfo
@export var resourceDmg:AttackInfo

@export var cuowa:NetworkCUOWA
func default_on_spawn(data:Array):
	cuowa.initCUOWA(self)
	Main.M.MainSceneManager.currentScene.add_child(self)
	self.position = data[0]
	print(self.position)
	
func on_spawn(data:Array): default_on_spawn(data)
func on_destroy(data:Array): pass

func _ready():
	setupAttkInfo(playerDmg)
	setupAttkInfo(enemyDmg)
	setupAttkInfo(buildingDmg)
	setupAttkInfo(resourceDmg)

func setupAttkInfo(attkInfo:AttackInfo):
	if attkInfo == null: return
	attkInfo = attkInfo.duplicate(true)
	attkInfo.setup()

#const damageTypes = [0, 1, 2, 3] #Base, Nature, Fire, Magic
const resistanceScalingFactor:float = .02
func calculate_dmg(against:HPContainer, attkInfo:AttackInfo) -> int:
	var rDmg:int = 0
	
	for dmgType:int in 4:
		rDmg += int(attkInfo.damage[dmgType] / (
			resistanceScalingFactor * against.resistances[dmgType] + 1.))
	
	return rDmg
