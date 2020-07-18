extends Node2D

func _ready():
	if OS.has_feature("server"):
		if get_tree().change_scene("res://server/Server.tscn"):
			print("Error changing scene to Client")
	else:
		if get_tree().change_scene("res://client/Login.tscn"):
			print("Couldn't return to login, something is deeply wonky, exiting process")

