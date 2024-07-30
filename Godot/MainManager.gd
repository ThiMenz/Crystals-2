class_name Main extends Node

## Essentially the parent of everything; so this root will never be
## deleted & can carry persistent infos - therefore the "Main"-Manager

@export var StartingScene:String
@export var MainSceneManager:SceneManager

func _ready():
	MainSceneManager.loadScene(StartingScene)
