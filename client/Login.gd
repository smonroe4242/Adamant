extends Control

onready var button = $CanvasLayer/CenterContainer/GridContainer/Button
onready var user = $CanvasLayer/CenterContainer/GridContainer/user
onready var passwd = $CanvasLayer/CenterContainer/GridContainer/passwd

func _enter_tree():
	print("INIT")
	if OS.has_feature("server"):
		print("Hi!")
		get_tree().change_scene("res://client/Client.tscn")
	else:
		print("CLI")

func _on_Button_pressed():
	Global.username = user.text
	Global.password = passwd.text
	get_tree().change_scene("res://client/Client.tscn")
