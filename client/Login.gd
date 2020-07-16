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
	Global.server_ip = IP.resolve_hostname(server.text, 1)
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
	print(server.text, ":", Global.server_ip)
# warning-ignore:unsafe_property_access
	Global.username = user.text
# warning-ignore:unsafe_property_access
	Global.password = passwd.text
	if get_tree().change_scene("res://client/Client.tscn"):
		print("Error changing to Client scene")
		if get_tree().change_scene("res://client/Login.tscn"):
			print("Couldn't return to login, something is deeply wonky, exiting process")
			get_tree().quit()
