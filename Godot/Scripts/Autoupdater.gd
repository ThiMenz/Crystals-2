extends Node

func _ready():
	$HTTPRequest.request_completed.connect(_on_request_completed)
	$HTTPRequest.request("https://github.com/ThiMenz/Crystals-2/raw/main/Godot/libterrain.windows.debug.x86_64.dll")

func _on_request_completed(result, response_code, headers, body:PackedByteArray):
	#var json = JSON.parse_string(body.get_string_from_utf8())
	print(result)
	print(response_code)
	print(headers)
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(body)
	var res = ctx.finish()
	print(res)
	#print(len(body.get_string_from_utf8()))
