extends Node2D

const SERVER_IP = "127.0.0.1"
const SERVER_PORT = 8910
const MAX_PLAYERS = 200
var players := {}
# Called when the node enters the scene tree for the first time.
func _enter_tree():
	var tree = get_tree()
	var peer = NetworkedMultiplayerENet.new()
	if OS.has_feature("server"):
		print("SERVER")
		tree.connect("network_peer_connected", self, "_client_connect")
		tree.connect("network_peer_disconnected", self, "_client_disconnect")
		peer.create_server(SERVER_PORT, MAX_PLAYERS)
		tree.network_peer = peer
		load_world({})
		print("READY")
	else:#elif OS.has_feature("client"):
		print("CLIENT")
#		var tree = get_tree()
		tree.connect("connected_to_server", self, "_server_connect")
		tree.connect("connection_failed", self, "_server_connect_fail")
		tree.connect("server_disconnected", self, "_server_disconnect")
		peer = NetworkedMultiplayerENet.new()
		peer.create_client(SERVER_IP, SERVER_PORT)
		tree.network_peer = peer
		print("READY")
func _server_connect():
	print("Client: server connected")
	rpc_id(1, "server_validate_login", get_tree().get_network_unique_id(), Global.username, Global.password)
	
func _server_connect_fail():
	print("Client: server connect failed")

func _server_disconnect():
	print("Client: server disconnected")
###
func _client_connect(id):
	print("Server: Client ", str(id), " connected")

func _client_disconnect(id):
	print("Server: Client ", str(id), " left")
	players.erase(id)
	for i in players:
		rpc_id(i, "remove_player", id)
	remove_player(id)

remote func server_validate_login(id, user, passwd):
	print("Server: Validating client ", str(id))
	if (user == "invalid"):
		rpc_id(id, "client_login_failed", "invalid user")
	else:
		for i in players:
			rpc_id(i, "load_player", id)
		players[id] = id
		rpc_id(id, "load_world", players)
		load_player(id)

remote func client_login_failed(id, err):
	print("Client: Login failed: ", str(err))

remote func remove_player(id):
	print("Server: removing player ", id)
	var parent = get_node("./World")
	var deadClient = parent.get_node(str(id))
	parent.remove_child(deadClient)

remote func load_world(people):
	print("Server: loading world with ", people)
	var world = preload("res://game/World.tscn").instance()
	get_node(".").add_child(world)
	
	for p in people:
		load_player(p)

remote func load_player(id):
	print("Client: loading player ", id)
	var selfId = get_tree().get_network_unique_id()
	var this_player = preload("res://game/Player.tscn").instance()
	this_player.set_name(str(id))
	this_player.set_network_master(id)
	this_player.get_node("Player/Camera2D").current = true if selfId == id else false
	get_node("./World").add_child(this_player)
