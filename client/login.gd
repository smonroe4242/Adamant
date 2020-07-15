extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	print("INIT")
	if OS.has_feature("server"):
		print("Hi!")
		get_tree().change_scene("res://client/Client.tscn")
	else:
		print("CLI")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
