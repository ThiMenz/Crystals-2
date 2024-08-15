class_name Stopwatch extends RefCounted

var swName:String
var timestamp:int = 0
func _init(pName = "Stopwatch", immidiateStart:bool = true):
	if immidiateStart: start()
	swName = pName
	
func start():
	timestamp = Time.get_ticks_usec()
	
func print_passed_time():
	print("[%] %ms".format([swName, (Time.get_ticks_usec() - timestamp) / 1000.], "%"))
