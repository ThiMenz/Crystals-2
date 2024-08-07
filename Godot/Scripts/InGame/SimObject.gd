class_name SimulationObject extends Node

var prevState = null
var curGoalState = null

var obj = null

func init_simState(pObj, pType):
	obj = pObj
	prevState = pType.new(pObj)
	curGoalState = pType.new(pObj)
	Main.M.Simulation.simulationObjects.append(self)

func switch_to_goal():
	prevState._copy(curGoalState)
	#prevState.switch_to_goal()

func interpolate(delta):
	prevState.interpolate(curGoalState, delta)
	
func simulation_process(delta:float): pass
