class_name Main extends Node

## Essentially the parent of everything; so this root will never be
## deleted & can carry persistent infos - therefore the "Main"-Manager

@export var MainSceneManager:SceneManager
@export var Game_Manager:GameManager
@export var UI:SceneManager
@export var Input_System:InputSystem

@export var td_raycast:RayCast3D

var Multiplayer:MultiplayerManager
var Simulation:SimulationManager

static var LinecastObj:RayCast3D

static var endingState := 0 ## 0 = Running without Biom Thread, 1 = Should End, 2 = Ended, 3 = Running with Biom Thread
static var endingStateMutex := Mutex.new()

static var SceneArgs := {}
static var M:Main # This way newly loaded nodes  can access pretty much everything through this object
static var Inp:InputSystem

static var USER_ID := ""

func initialSaveSystemLoad():
	LinecastObj = td_raycast
	
	SaveSystem._load()
	if !SaveSystem.data.has("UserID"): SaveSystem.data["UserID"] = GenerateUserID()
	if !SaveSystem.data.has("Worlds"): SaveSystem.data["Worlds"] = {}
	
	Game_Manager.worlds = SaveSystem.data["Worlds"]
	Inp = Input_System
	USER_ID = SaveSystem.data["UserID"]

func updateSceneArgs(pArgs:Dictionary):
	for arg in pArgs: 
		SceneArgs[arg] = pArgs[arg]

func _ready():
	M = self
	initialSaveSystemLoad()
	
	Engine.max_fps = 250
	
	UI.loadScene("MainMenu")
	
func GenerateUserID() -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for address in IP.get_local_addresses(): ctx.update(var_to_bytes(address))
	var res:PackedByteArray = ctx.finish()
	for i in 16: # 1 in ~3*10^38 + same IP hash
		res.append(randi_range(0, 255))	
	const USER_ID_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789?!"
	var userID := ""
	for i in 16:
		var t1 = res[i * 3]
		var t2 = res[i * 3 + 1]
		var t3 = res[i * 3 + 2]
		userID += USER_ID_CHARS[t1 & 63]
		userID += USER_ID_CHARS[((t1 & 192) >> 2) | (t2 & 15)]
		userID += USER_ID_CHARS[((t2 & 240) >> 2) | (t3 & 3)]
		userID += USER_ID_CHARS[((t3 & 252) >> 2)]
	return userID

func GetCmdLineArgDict() -> Dictionary:
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			arguments[argument.lstrip("--")] = ""
	return arguments

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit()

## Will be called on pretty much every application closure 
## Alt+F4, Taskmanager Force Quit, Window "X" and Quit Btn
## Internal Restart Button in the godot editor is an exception!
## TODO test PID-CMD-closure - but should be the same as Taskmanager
func _quit(): 
	stopBiomThread()
	SaveSystem._save()
	get_tree().quit()
	
func stopBiomThread():
	endingStateMutex.lock()
	if endingState == 3:
		endingState = 1
		endingStateMutex.unlock()
		var b:bool = true
		while b:
			endingStateMutex.lock()
			b = endingState != 2
			endingStateMutex.unlock()
	else: endingStateMutex.unlock()
	endingState = 0
	
signal worldSelected(worldName)
