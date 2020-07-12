extends Node2D

const PORT = 8910
const MAX_PLAYERS = 200
var players := {}

func _ready():
	var tree = get_tree()
	tree.connect("network_peer_connected", self, "_client_connect")
	tree.connect("network_peer_disconnected", self, "_client_disconnect")
	var server = NetworkedMultiplayerENet.new()
	server.create_server(PORT, MAX_PLAYERS)	
	tree.network_peer = server
	load_world({})

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
	#queue_free()

remote func remove_player(id):
	print("Server: removing player ", id)
	var parent = get_node("./World")
	var deadClient = parent.get_node(str(id))
	parent.remove_child(deadClient)
	

remote func load_world(people):
	print("Server: loading world with ", people)
	var world = preload("res://common/World.tscn").instance()
	get_node(".").add_child(world)
	
	for p in people:
		load_player(p)

remote func load_player(id):
	print("Server: loading player", id)
	var this_player = preload("res://common/Player.tscn").instance()
	this_player.set_name(str(id))
	this_player.set_network_master(id)
	this_player.get_node("Player/Camera2D").current = false
	get_node("./World").add_child(this_player)
