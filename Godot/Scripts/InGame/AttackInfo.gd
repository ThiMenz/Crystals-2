class_name AttackInfo extends Resource

@export var neutralDmg:int = 0
@export var natureDmg:int = 0
@export var fireDmg:int = 0
@export var magicDmg:int = 0

var damage = []

func setup():
	damage = [neutralDmg, natureDmg, fireDmg, magicDmg]
