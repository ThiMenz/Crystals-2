class_name Main extends Node

## Essentially the parent of everything; so this root will never be
## deleted & can carry persistent infos - therefore the "Main"-Manager

@export var MainSceneManager:SceneManager
@export var UI:SceneManager

static var SceneArgs := {}
static var M:Main # This way newly loaded nodes  can access pretty much everything through this object

func _ready():
	M = self
	SaveSystem._load()
	
	UI.loadScene("MainMenu")

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
## TODO test PID-CMD-closure - but should be the same as Taskmanager
func _quit(): 
	SaveSystem._save()
	get_tree().quit()
	
signal worldSelected(worldName)

