extends Control

onready var server = $CanvasLayer/CenterContainer/WindowDialog/GridContainer/server
onready var user = $CanvasLayer/CenterContainer/WindowDialog/GridContainer/user
onready var passwd = $CanvasLayer/CenterContainer/WindowDialog/GridContainer/passwd
onready var error = $CanvasLayer/CenterContainer/WindowDialog/GridContainer/Error

func _ready():
	server.text = "127.0.0.1"
	user.text = Global.username
	passwd.text = ""
	error.text = Global.error
	if user.text == "":
		user.grab_focus()
	elif passwd.text == "":
		passwd.grab_focus()
	$CanvasLayer/CenterContainer/WindowDialog.popup()

func _on_Button_pressed():
	$AudioStreamPlayer.play_confirm()
	var ip = IP.resolve_hostname(server.text, 1)
	Global.server_ip = ip
	print("Client: Login: resolve_hostname(): ", server.text, ":", Global.server_ip)
	Global.username = user.text
	Global.password = passwd.text
	if get_tree().change_scene("res://client/Client.tscn"):
		print("Client: Error changing to Client scene")
		if get_tree().change_scene("res://client/Login.tscn"):
			print("Client: Couldn't return to login, something is deeply wonky, exiting process")
			get_tree().quit()
