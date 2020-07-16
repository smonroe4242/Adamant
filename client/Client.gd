extends Node2D

const SERVER_PORT = 8910
const MAX_PLAYERS = 200
var players := {}
var spawn := {}
# Called when the node enters the scene tree for the first time.
func _enter_tree():
	var editor_be_server = false
	if editor_be_server:
		if OS.has_feature("client"):
			init_client()
		else:
			init_server()
	else: # normal build mode
		if OS.has_feature("server"):
			init_server()
		else:
			init_client()

func init_client():
	print("CLIENT")
	var tree = get_tree()
	tree.set_debug_collisions_hint(false)
	var peer = NetworkedMultiplayerENet.new()
	tree.connect("connected_to_server", self, "_server_connect")
	tree.connect("connection_failed", self, "_server_connect_fail")
	tree.connect("server_disconnected", self, "_server_disconnect")
# warning-ignore:unsafe_property_access
	peer.create_client(Global.server_ip, SERVER_PORT)
	tree.network_peer = peer
	print("READY")

func init_server():
	print("SERVER")
	var tree = get_tree()
	var peer = NetworkedMultiplayerENet.new()
	tree.connect("network_peer_connected", self, "_client_connect")
	tree.connect("network_peer_disconnected", self, "_client_disconnect")
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	load_world_server()
	tree.network_peer = peer
	print("READY")
#c
func _server_connect():
	print("Client: server connected")
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
	rpc_id(1, "server_validate_login", get_tree().get_network_unique_id(), Global.username, Global.password)
#c
func _server_connect_fail():
	print("Client: server connect failed")
#c
func _server_disconnect():
	print("Client: server disconnected")
#s
func _client_connect(id):
	print("Server: Client ", str(id), " connected")
#s
func _client_disconnect(id):
	print("Server: Client ", str(id), " left")
# warning-ignore:return_value_discarded
	spawn[players[id]] = get_node("./World/" + str(id)).position
	players.erase(id)
	for i in players:
		rpc_id(i, "remove_player", id)
	remove_player(id)

remote func server_validate_login(id, user, passwd):
	print("Server: Validating client ", str(id))
	if (user == "invalid" or passwd == user):
		rpc_id(id, "client_login_failed", "invalid user")
		print("username bad! ", user)
	else:
		print("username good ", user)
		if not user in spawn.keys():
			spawn[user] = Vector2(512,512)
		load_player(id, user, spawn[user])
		rpc_id(id, "load_world", spawn[user])
		rpc_id(id, "load_player", id, user, spawn[user])
		for i in players.keys():
			rpc_id(i, "load_player", id, user, spawn[user])
			rpc_id(id, "load_player", i, players[i], spawn[players[i]])
		players[id] = user
#c
remote func client_login_failed(err):
	print("Client: Login failed for player: ", str(err))
	if not get_tree().change_scene("res://client/Login.tscn"):
		print("Error changing scene to Login")
#b
remote func remove_player(id):
	print("removing player ", id)
	var parent = get_node("./World")
	var deadClient = parent.get_node(str(id))
	if not deadClient == null:
		deadClient.queue_free()
#c
remote func load_world(origin):
	var world = preload("res://game/World.tscn").instance()
	world.origin = origin
	get_node(".").add_child(world)
#s
func load_world_server():
	var world = Node2D.new()
	world.name = "World"
	get_node(".").add_child(world)
#b
remote func load_player(id, username, origin):
	print("loading player ", username)
	var selfId = get_tree().get_network_unique_id()
	var this_player = preload("res://game/Player.tscn").instance()
	this_player.set_name(str(id))
	this_player.set_display_name(username)
	this_player.position = origin
	if selfId == id: # owning client
		this_player.set_network_master(id)
		this_player.get_node("Camera2D").current = true
	elif selfId == 1:
	# server replica, would like to replace with shallow clone with only vars and rpcs
		this_player.set_network_master(id)
		this_player.get_node("Camera2D").current = false
	else: # client replica
		this_player.set_network_master(1)
		this_player.get_node("Camera2D").current = false
	get_node("./World").call_deferred("add_child", this_player)
