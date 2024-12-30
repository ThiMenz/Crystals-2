extends Node

#@export var PARAM_NAMES:Array[StringName]
#@export var PARAM_VALS:Array
@export var PARAM_NAME:StringName
@export var VAL:float

func _ready():
	updateShader()

func updateShader():
	self.material_override.set_shader_parameter(PARAM_NAME, VAL)
	#var a := 0
	#for tName in PARAM_NAMES:
	#	self.material_override.set_shader_parameter(tName, PARAM_VALS[a])
	#	a += 1

func _process(delta):
	updateShader()
