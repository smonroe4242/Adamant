extends Node2D

const SERVER_IP = "127.0.0.1"
const SERVER_PORT = 8910

# Called when the node enters the scene tree for the first time.
func _ready():
	var tree = get_tree()
	tree.connect("connected_to_server", self, "_server_connect")
	tree.connect("connection_failed", self, "_server_connect_fail")
	tree.connect("server_disconnected", self, "_server_disconnect")
	var client = NetworkedMultiplayerENet.new()
	client.create_client(SERVER_IP, SERVER_PORT)
	get_tree().network_peer = client
	print("Connected?")

func _server_connect():
	print("Client: server connected")
	
func _server_connect_fail():
	print("Client: server connect failed")

func _server_disconnect():
	print("Client: server disconnected")

remote func remove_player(id):
	var parent = get_node("./World")
	var deadClient = parent.get_node(str(id))
	parent.remove_child(deadClient)
	print("Client: removed ", deadClient)

remote func load_world(players):
	print("Client: loading world")
	var world = preload("res://common/World.tscn").instance()
	get_node(".").add_child(world)

	for p in players:
		load_player(p)

remote func load_player(id):
	print("Client: loading player ", id)
	var selfId = get_tree().get_network_unique_id()
	var this_player = preload("res://common/Player.tscn").instance()
	this_player.set_name(str(id))
	this_player.set_network_master(id)
	this_player.get_node("Player/Camera2D").current = true if selfId == id else false
	get_node("./World").add_child(this_player)
