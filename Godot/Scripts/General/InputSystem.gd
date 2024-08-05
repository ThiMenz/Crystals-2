class_name InputSystem extends Node

## These need to be the same as in the Input Management Tab as in the Project Settings
@export var KeyboardActionNames:Array[String] = [
	"MoveDown",
	"MoveUp",
	"MoveLeft",
	"MoveRight"
]

## Example Usage: InputSystem.KeyboardActions["Name"].hold
var KeyboardActions = { }
var keyboardActionCount

func ActionDown(pAction: String) -> float:
	return KeyboardActions[pAction].down
	
func ActionHold(pAction: String) -> float:
	return KeyboardActions[pAction].hold
	
func ActionUp(pAction: String) -> float:
	return KeyboardActions[pAction].up

## Init Input DataClasses
func _ready():
	keyboardActionCount = KeyboardActionNames.size()
	for i in keyboardActionCount:
		KeyboardActions[KeyboardActionNames[i]] = InputFrame.new(KeyboardActionNames[i])

## Needs to get called in the last _process call
## At least after every input check
func FrameEndInputManagement():
	for itKeyboardAction in KeyboardActionNames:
		KeyboardActions[itKeyboardAction].down = 0.
		if (KeyboardActions[itKeyboardAction].up != .0):
			KeyboardActions[itKeyboardAction].up = 0.
			KeyboardActions[itKeyboardAction].hold = 0.
			
	
## On Input Event:
## Check every ActionName for Release / Press Down
## And in case: Update the Input DataClasses
func _input(event:InputEvent):	
	if !event.is_action_type(): return
	
	for itKeyboardAction in KeyboardActionNames:
		if (event.is_action_pressed(itKeyboardAction)):
			KeyboardActions[itKeyboardAction].down = 1.
			KeyboardActions[itKeyboardAction].hold = 1.
		
		if (event.is_action_released(itKeyboardAction)):
			KeyboardActions[itKeyboardAction].up = 1.
