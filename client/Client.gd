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
		load_world({})
		print("READY")
	else:
		print("CLIENT")
		tree.connect("connected_to_server", self, "_server_connect")
		tree.connect("connection_failed", self, "_server_connect_fail")
		tree.connect("server_disconnected", self, "_server_disconnect")
		peer.create_client(SERVER_IP, SERVER_PORT)
		print("READY")
	tree.network_peer = peer

func _server_connect():
	print("Client: server connected")
	
func _server_connect_fail():
	print("Client: server connect failed")

func _server_disconnect():
	print("Client: server disconnected")

func _client_connect(id):
	print("Server: Client ", str(id), " connected")
	for i in players:
		rpc_id(i, "load_player", id)
	players[id] = id
	rpc_id(id, "load_world", players)
	load_player(id)

func _client_disconnect(id):
	print("Server: Client ", str(id), " left")
	players.erase(id)
	for i in players:
		rpc_id(i, "remove_player", id)
	remove_player(id)

remote func remove_player(id):
	print("removing player ", id)
	var parent = get_node("./World")
	var deadClient = parent.get_node(str(id))
	parent.remove_child(deadClient)
	deadClient.queue_free()

remote func load_world(people):
	print("loading world with ", people)
	var world = preload("res://game/World.tscn").instance()
	get_node(".").add_child(world)
	
	for p in people:
		load_player(p)

remote func load_player(id):
	print("loading player ", id)
	var selfId = get_tree().get_network_unique_id()
	var this_player = preload("res://game/Player.tscn").instance()
	this_player.set_name(str(id))
	this_player.set_network_master(id)
	if selfId == id:
		this_player.get_node("Player/Camera2D").current = true
		this_player.position = Vector2(-5, -400)
	else:
		this_player.get_node("Player/Camera2D").current = false
	get_node("./World").add_child(this_player)
