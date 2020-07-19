extends Control

onready var server = $CanvasLayer/CenterContainer/GridContainer/server
onready var user = $CanvasLayer/CenterContainer/GridContainer/user
onready var passwd = $CanvasLayer/CenterContainer/GridContainer/passwd
onready var error = $CanvasLayer/CenterContainer/GridContainer/Error

func _ready():
	server.text = "127.0.0.1"
	user.text = Global.username
	passwd.text = ""
	error.text = Global.error

func _on_Button_pressed():
	var ip = IP.resolve_hostname(server.text, 1)
	print("Login: resolve_hostname(): ", ip)
	Global.server_ip = ip
	print(server.text, ":", Global.server_ip)
	Global.username = user.text
	Global.password = passwd.text
	if get_tree().change_scene("res://client/Client.tscn"):
		print("Error changing to Client scene")
		if get_tree().change_scene("res://client/Login.tscn"):
			print("Couldn't return to login, something is deeply wonky, exiting process")
			get_tree().quit()
