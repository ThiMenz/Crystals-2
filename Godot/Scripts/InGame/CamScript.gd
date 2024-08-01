extends Node3D


func _ready():
	#Engine.max_fps = 400
	pass
	
var passedTimeSinceFPSUpdate:float = .0

func _process(delta):
	
	passedTimeSinceFPSUpdate += delta
	if passedTimeSinceFPSUpdate > .1:
		$FPSCounter.text = str(int(1/delta)) + " FPS"
		passedTimeSinceFPSUpdate = .0
	
	var m:float = delta * 50
	var r:float = delta * 3
	
	if Input.is_key_pressed(KEY_RIGHT):
		self.position += Vector3(m, 0, 0)
	if Input.is_key_pressed(KEY_LEFT):
		self.position -= Vector3(m, 0, 0)
		
	if Input.is_key_pressed(KEY_DOWN):
		self.position+= Vector3(0, 0, m)
	if Input.is_key_pressed(KEY_UP):
		self.position -= Vector3(0, 0, m)
		
	if Input.is_key_pressed(KEY_W):
		self.position += Vector3(0, m, 0)
	if Input.is_key_pressed(KEY_S):
		self.position -= Vector3(0, m, 0)
		
	if Input.is_key_pressed(KEY_E):
		self.rotation += Vector3(r, 0, 0)
		
	if Input.is_key_pressed(KEY_D):
		self.rotation -= Vector3(r, 0, 0)
		
	if Input.is_key_pressed(KEY_R):
		self.rotation += Vector3(0, r, 0)
		
	if Input.is_key_pressed(KEY_F):
		self.rotation -= Vector3(0, r, 0)
