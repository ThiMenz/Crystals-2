class_name SceneManager extends Node

## Can be used recursively (for subscenes like topdown & platforming e.g.)
## Thats also the place for scene transitions later

@export var scenes:Dictionary = {}

func loadScene(name):
	var tScene = scenes[name].instantiate()
	add_child(tScene)
