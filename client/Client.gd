extends Node2D
var character_options = []
onready var audio_player = $AudioStreamPlayer
onready var sfx_player = $AudioStreamPlayer/SFX
# Called when the node enters the scene tree for the first time.
func _enter_tree():
	$UI/CanvasLayer/TextureButton.hide()
	init_client()

func init_client():
	var tree = get_tree()
	var peer = NetworkedMultiplayerENet.new()
	tree.connect("connected_to_server", self, "_server_connect")
	tree.connect("connection_failed", self, "_server_connect_fail")
	tree.connect("server_disconnected", self, "_server_disconnect")
	var err = peer.create_client(Global.server_ip, Global.server_port)
	if err:
		client_login_failed(err)
	tree.network_peer = peer
	print("Client: READY")

func _server_connect():
	print("Client: server connected")
	rpc_id(1, "server_validate_login", get_tree().get_network_unique_id(), Global.username, Global.password)

func _server_connect_fail():
	print("Client: server connect failed")
	client_login_failed("Failed to connect to realm")

func _server_disconnect():
	print("Client: server disconnected")
	client_login_failed("Disconnected from realm")
	
func create_character(user, _name, _class):
	Global.character_name = _name
	rpc_id(1, "server_create_character", get_tree().get_network_unique_id(), user, _name, _class)

func select_character(user, character):
	Global.character_name = character_options[character].name
	rpc_id(1, "server_select_character", get_tree().get_network_unique_id(), user, character)

remote func client_load_character_list(characters):
	if characters == null or characters.size() == 0:
		$CharCreate.popup()
	else:
		character_options = characters
		for character in characters:
			$CharSelect/ItemList.add_item(character.name + ", level " + str(character.level) + " " + Global.class_strings[character.class])
		$CharSelect.popup()
	pass

remote func client_login_failed(err):
	print("Client: Login failed")
	if err is int:
		Global.set_err_msg(err, true)
	else:
		Global.error = err
	if get_tree().change_scene("res://client/Login.tscn"):
		print("Client: Error changing scene to Login")
	else:
		print("Client: Success changing to Login")

remote func load_world(origin):
	var world = preload("res://game/World.tscn").instance()
	world.origin = origin
	get_node(".").add_child(world)
	$UI/CanvasLayer/TextureButton.show()

remote func load_player(id, username, origin, _class, level, new_attributes):
	print("Client: loading player ", username)
	var this_player = preload("res://game/Player.tscn").instance()
	this_player.set_name(str(id))
	this_player.set_display_name(username)
	this_player.position = origin
	this_player.classtype = _class
	this_player.level = level
	this_player.attributes = new_attributes
	this_player.set_network_master(id)
	this_player.get_node("Camera2D").current = true
	this_player.connect("player_entered", get_node("./World"), "player_entered")
	Global.player_node = this_player
	print("Client: LOAD_PLAYER: hp: ", this_player.attributes.hp, ", max_hp: ", this_player.attributes.max_hp, ", stam: ", this_player.attributes.stamina)
	get_node("./World").call_deferred("add_child", this_player)
