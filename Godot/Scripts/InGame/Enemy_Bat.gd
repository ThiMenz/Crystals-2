class_name Enemy_Bat extends EnemyBase

@export var speed:float = 5.

func on_spawn(data:Array): 
	spawn_setup(data)

func simulation_process(delta:float):

	updateTarget()
	updatePath()
	var curPos := moveAlongPath(speed * delta)
	
	curGoalState.set_state(curPos)
