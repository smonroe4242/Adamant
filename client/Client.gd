extends Node2D
# Called when the node enters the scene tree for the first time.
func _enter_tree():
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

remote func load_player(id, username, origin, max_hp, hp, strength, stamina, intellect, wisdom, dexterity, luck):
	print("Client: loading player ", username)
	var this_player = preload("res://game/Player.tscn").instance()
	this_player.set_name(str(id))
	this_player.set_display_name(username)
	this_player.position = origin
	this_player.max_hp = max_hp
	this_player.hp = hp
	this_player.strength = strength
	this_player.stamina = stamina
	this_player.intellect = intellect
	this_player.wisdom = wisdom
	this_player.dexterity = dexterity
	this_player.luck = luck
	this_player.set_network_master(id)
	this_player.get_node("Camera2D").current = true
	this_player.connect("player_entered", get_node("./World"), "player_entered")
	Global.player_node = this_player
	print("Client: LOAD_PLAYER: hp: ", this_player.hp, ", max_hp: ", this_player.max_hp)
	get_node("./World").call_deferred("add_child", this_player)
