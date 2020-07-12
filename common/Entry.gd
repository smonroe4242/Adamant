extends Node2D

func _enter_tree():
#func _ready():
	print("Application started")

	if OS.has_feature("server"):
		print("Is server")
		get_tree().change_scene("res://server/Server.tscn")
	elif OS.has_feature("client"):
		print("Is client")
		get_tree().change_scene("res://client/Client.tscn")
	# When running from the editor, this is how we'll default to being a client
	else:
		print("Could not detect application type! Defaulting to client.")
		#get_tree().change_scene("res://server/Server.tscn")
		get_tree().change_scene("res://client/Client.tscn")
