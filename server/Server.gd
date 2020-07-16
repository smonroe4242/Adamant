extends Node2D

const MAX_PLAYERS = 200
var players := {}
var spawn := {}
# Called when the node enters the scene tree for the first time.
func _enter_tree():
	init_server()

func init_server():
	print("SERVER")
	var tree = get_tree()
	var peer = NetworkedMultiplayerENet.new()
	tree.connect("network_peer_connected", self, "_client_connect")
	tree.connect("network_peer_disconnected", self, "_client_disconnect")
	peer.create_server(Global.server_port, MAX_PLAYERS)
	load_world_server()
	tree.network_peer = peer
	print("READY")

func _client_connect(id):
	print("Server: Client ", str(id), " connected")

func _client_disconnect(id):
	print("Server: Client ", str(id), " left")
# warning-ignore:unsafe_property_access
	spawn[players[id]] = get_node("./World/" + str(id)).position
# warning-ignore:return_value_discarded
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
		load_player_server(id, user, spawn[user])
		rpc_id(id, "load_world", spawn[user])
		rpc_id(id, "load_player", id, user, spawn[user])
		for i in players.keys():
			rpc_id(i, "load_player", id, user, spawn[user])
			rpc_id(id, "load_player", i, players[i], spawn[players[i]])
		players[id] = user

func remove_player(id):
	print("Server: removing player ", id)
	var parent = get_node("./World")
	var deadClient = parent.get_node(str(id))
	if not deadClient == null:
		deadClient.queue_free()

func load_world_server():
	print("Server: loading world")
	var world = Node2D.new()
	world.name = "World"
	get_node(".").add_child(world)

func load_player_server(id, username, origin):
	print("Server: loading player ", username)
	var this_player = preload("res://server/ServerPlayer.tscn").instance()
	this_player.set_name(str(id))
	this_player.position = origin
	this_player.set_network_master(id)
	get_node("./World").call_deferred("add_child", this_player)
