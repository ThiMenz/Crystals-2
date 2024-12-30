class_name HPContainer extends Resource

@export_subgroup("HP")
@export var maxHP = 0
@export var startHP = 0

@export_subgroup("Resistance")
@export var neutralResistance = 0
@export var natureResistance = 0
@export var fireResistance = 0
@export var magicResistance = 0

var HP:int
var CUOWA:NetworkCUOWA
var resistances := []

func setup(pCuowa:NetworkCUOWA):
	HP = startHP
	resistances = [neutralResistance, natureResistance, fireResistance, magicResistance]
	CUOWA = pCuowa

@rpc("any_peer", "call_local", "reliable")
func change_hp(hpChange:int):
	HP -= hpChange
	if HP < 1: kill.rpc()
		
@rpc("any_peer", "call_local", "reliable")
func kill():
	CUOWA.mainObj.kill()
