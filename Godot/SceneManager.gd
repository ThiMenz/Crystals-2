class_name SceneManager extends Node

## Can be used recursively (for subscenes like topdown & platforming e.g.)
## Thats also the place for scene transitions later

@export var scenes:Dictionary = {}
@export var storeSceneHistory:bool = false

## TODO Memory overload currently theoratically possible, but tbf pretty 
## much nobody clicks a million (or even more) UI buttons in one runtime xD
var sceneHistory:Array[String] = []
var currentScene = null

func loadScene(name:String, args:Dictionary = {}):
	if currentScene != null: currentScene.queue_free() 
	
	var tScene = scenes[name].instantiate()
	add_child(tScene)
	currentScene = tScene
	if storeSceneHistory:
		sceneHistory.append(name)	
		
	Main.SceneArgs = args
	
func goBack():
	var tL:int = len(sceneHistory)
	var tScene = sceneHistory[tL-2]
	sceneHistory.remove_at(tL-1)
	sceneHistory.remove_at(tL-2)
	loadScene(tScene)
