class_name SceneManager extends Node

## Can be used recursively (for subscenes like topdown & platforming e.g.)
## Thats also the place for scene transitions later

@export var scenes:Dictionary = {}
@export var storeSceneHistory:bool = false

const maxSceneHistoryCount = 1024 ## To prevent memory overload
var sceneHistory:Array[String] = []
var currentScene = null

func loadScene(name:String, args:Dictionary = {}):
	unload()
	
	var tScene = scenes[name].instantiate()
	add_child(tScene)
	currentScene = tScene
	if storeSceneHistory:
		sceneHistory.append(name)	
		if len(sceneHistory) > maxSceneHistoryCount:
			sceneHistory.remove_at(0)
		
	for arg in args: Main.SceneArgs[arg] = args[arg]
	
func goBack():
	var tL:int = len(sceneHistory)
	var tScene = sceneHistory[tL-2]
	sceneHistory.remove_at(tL-1)
	sceneHistory.remove_at(tL-2) ## Could through error if maxSceneHistoryCount's "UI depth" is reached
	loadScene(tScene)
	
func unload():
	if currentScene != null: currentScene.queue_free() 
