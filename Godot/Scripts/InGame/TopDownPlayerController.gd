class_name TDPlayerController extends SimulationObject

## TODO Controller Support (requires InputSystem upgrade)

@export var td_speed := 5

@export var td_dirPrecision := 32 ## can't be lower than 8 and should be a power of 2
@export var td_maxDirDeviation := 7 ## should be less than a quarter of td_dirPrecision

@export var td_shapecast:ShapeCast3D
@export var td_raycast:RayCast3D

var precalcDirs:Array[Vector3] = [] ## goes anti-clockwise
var precalcKeyInp:Array[int] = [-1, 8, 24, -1, 0, 4, 28, 0, 16, 12, 20, 16, -1, 8, 24, -1] ## for 32 dirs
var precalcIsDiag:Array[bool] = [false, false, false, false, false, true, true, false, false, true, true, false, false, false, false, false]
func player_ready(startPos:Vector3):
	
	self.position = startPos
	init_simState(self, PlayerSimState)
	
	var tHalfDirPrecision = td_dirPrecision / 2
	for i in td_dirPrecision:
		var t:float = (PI / tHalfDirPrecision) * i
		precalcDirs.append(Vector3(cos(t), 0, -sin(t)))
		
func simulation_process(delta:float):
	
	var tKeyInp:int = int(
		Main.Inp.ActionHold("MoveUp") != .0) | (int(
		Main.Inp.ActionHold("MoveDown") != .0) << 1) | (int(
		Main.Inp.ActionHold("MoveRight") != .0) << 2) | (int(
		Main.Inp.ActionHold("MoveLeft") != .0) << 3)
	var tDir:int = precalcKeyInp[tKeyInp]
		
	if tDir == -1: return

	var tMovementMult:float = delta * td_speed
	var tPrefMovement:Vector3 = precalcDirs[tDir] * tMovementMult
	var tBestVec := Utils.Linecast3D(self.position, tPrefMovement)
	var tFoundDir := true
	
	## If an obstacle is in the way, try to find a similar direction to walk in
	if tBestVec != tPrefMovement:
		tFoundDir = false
		var tClDeviation:int = tDir
		var tAClDeviation:int = tDir
		
		for i in td_maxDirDeviation:
			tClDeviation += 1
			if tClDeviation == td_dirPrecision: tClDeviation = 0
			if tAClDeviation == 0: tAClDeviation = td_dirPrecision
			tAClDeviation -= 1
			
			var tCLMov := precalcDirs[tClDeviation] * tMovementMult
			var tCLVec := Utils.Linecast3D(self.position, tCLMov)
			if tCLMov == tCLVec: 
				tBestVec = tCLVec
				tFoundDir = true
				break
				
			var tACLMov := precalcDirs[tAClDeviation] * tMovementMult
			var tACLVec := Utils.Linecast3D(self.position, tACLMov)
			if tACLMov == tACLVec: 
				tBestVec = tACLVec
				tFoundDir = true
				break

	if tFoundDir:
		curGoalState.set_state(self.position + tBestVec) 
