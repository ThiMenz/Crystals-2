class_name SceneManager extends Node

## Can be used recursively (for subscenes like topdown & platforming e.g.)
## Thats also the place for scene transitions later

@export var scenes:Dictionary = {}
@export var defaultSceneHirachy:Dictionary = {}
@export var storeSceneHistory:bool = false

const maxSceneHistoryCount = 1024 ## To prevent memory overload
var sceneHistory:Array[String] = []
var currentScene = null
var currentSceneName:String = ""

func loadScene(name:String, args:Dictionary = {}):
	unload()
	
	var tScene = scenes[name].instantiate()
	add_child(tScene)
	currentScene = tScene
	currentSceneName = name
	if storeSceneHistory:
		sceneHistory.append(name)	
		if len(sceneHistory) > maxSceneHistoryCount:
			sceneHistory.remove_at(0)
		
	Main.M.updateSceneArgs(args)
	
func goBack():
	var tL:int = len(sceneHistory)
	if tL < 2:
		if defaultSceneHirachy.has(currentSceneName):
			if tL != 0: sceneHistory.remove_at(tL-1)
			loadScene(defaultSceneHirachy[currentSceneName])
		
		return
	var tScene = sceneHistory[tL-2]
	sceneHistory.remove_at(tL-1)
	sceneHistory.remove_at(tL-2) ## Could throw error if maxSceneHistoryCount's "UI depth" is reached
	loadScene(tScene)
	
func clearSceneHistory():
	sceneHistory.clear()
	
func unload():
	if currentScene != null: currentScene.queue_free() 
