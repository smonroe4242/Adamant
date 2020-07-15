extends Node2D

const SERVER_IP = "127.0.0.1"
const SERVER_PORT = 8910
const MAX_PLAYERS = 200
var players := {}
# Called when the node enters the scene tree for the first time.
func _enter_tree():
	var tree = get_tree()
	var peer = NetworkedMultiplayerENet.new()
	var editor_be_server = false
	if editor_be_server:
		if OS.has_feature("client"):
			print("CLIENT")
			tree.connect("connected_to_server", self, "_server_connect")
			tree.connect("connection_failed", self, "_server_connect_fail")
			tree.connect("server_disconnected", self, "_server_disconnect")
			peer.create_client(SERVER_IP, SERVER_PORT)
			load_world()
			print("READY")
		else:
			print("SERVER")
			tree.connect("network_peer_connected", self, "_client_connect")
			tree.connect("network_peer_disconnected", self, "_client_disconnect")
			peer.create_server(SERVER_PORT, MAX_PLAYERS)
			load_world()
			print("READY")
	else: # normal build mode
		if OS.has_feature("server"):
			print("SERVER")
			tree.connect("network_peer_connected", self, "_client_connect")
			tree.connect("network_peer_disconnected", self, "_client_disconnect")
			peer.create_server(SERVER_PORT, MAX_PLAYERS)
			load_world()
			print("READY")
		else:
			print("CLIENT")
			tree.connect("connected_to_server", self, "_server_connect")
			tree.connect("connection_failed", self, "_server_connect_fail")
			tree.connect("server_disconnected", self, "_server_disconnect")
			peer.create_client(SERVER_IP, SERVER_PORT)
			load_world()
			print("READY")
	tree.network_peer = peer
#c
func _server_connect():
	print("Client: server connected")
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
	players.erase(id)
	for i in players:
		rpc_id(i, "remove_player", id)
# should we call this? Aren;t they already gone?
#	rpc_id(id, "remove_player", id)
	remove_player(id)

remote func server_validate_login(id, user, passwd):
	print("Server: Validating client ", str(id))
	if (user == "invalid" or passwd == user):
		rpc_id(id, "client_login_failed", "invalid user")
		print("username! ", user)
	else:
		print("username ", user)
		load_player(id, user)
		rpc_id(id, "load_world")
		rpc_id(id, "load_player", id, user)
		for i in players.keys():
			rpc_id(i, "load_player", id, user)
			rpc_id(id, "load_player", i, players[i])
		players[id] = user

remote func client_login_failed(err):
	print("Client: Login failed for player: ", str(err))
	get_tree().change_scene("res://client/Login.tscn")
#b
remote func remove_player(id):
	print("removing player ", id)
	var parent = get_node("./World")
	var deadClient = parent.get_node(str(id))
	print("got node from parent")
	if not deadClient == null:
		deadClient.queue_free()
#b, server shouldnt need world except for tree structure
remote func load_world():
	var world = preload("res://game/World.tscn").instance()
	get_node(".").add_child(world)
#b
remote func load_player(id, username):
	print("loading player ", username)
	var selfId = get_tree().get_network_unique_id()
	var this_player = preload("res://game/Player.tscn").instance()
	this_player.set_name(str(id))
	this_player.set_network_master(id)
	this_player.get_node("Player/Camera2D").current = true if selfId == id else false
	this_player.get_node("Player").set_display_name(username)
	get_node("./World").call_deferred("add_child", this_player)
