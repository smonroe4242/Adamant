extends Control

onready var server = $CanvasLayer/CenterContainer/GridContainer/server
onready var user = $CanvasLayer/CenterContainer/GridContainer/user
onready var passwd = $CanvasLayer/CenterContainer/GridContainer/passwd

func _enter_tree():
	print("INIT")
	if OS.has_feature("server"):
		print("Hi!")
		if not get_tree().change_scene("res://client/Client.tscn"):
			print("Error changing scene to Client")
	else:
		print("CLI")

func _on_Button_pressed():
# warning-ignore:unsafe_property_access
	Global.server_ip = server.text
# warning-ignore:unsafe_property_access
	Global.username = user.text
# warning-ignore:unsafe_property_access
	Global.password = passwd.text
	if not get_tree().change_scene("res://client/Client.tscn"):
		print("Error changing to Client scene")
