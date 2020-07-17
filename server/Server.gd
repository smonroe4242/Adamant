extends Node2D

const MAX_PLAYERS = 200
var players := {}
var current := {}
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
	if current[id] == null:
		print("Not a current player")
		return
	var deadClient = get_node("./World/" + str(id))
	if deadClient == null:
		print("Not a node in tree")
		return
	players[current[id].name].spawn = deadClient.position
# warning-ignore:return_value_discarded
	current.erase(id)
	for i in current:
		rpc_id(i, "remove_player", id)
	print("Server: removing player ", id)
	if not deadClient == null:
		deadClient.queue_free()

func validate_user(id, user, passwd):
	if players[user] == null:
		print("Server: New Player: ", user, " as ", id)
		players[user] = {'passwd': hash(passwd), 'spawn': Vector2(512, 512)}
		print("Testing only: ", passwd, " hashes to ", hash(passwd))
	else:
		print("Server: Old Player: ", user, " as ", id)
		if players[user].passwd != hash(passwd):
			print("Server: Bad login")
			rpc_id(id, "client_login_failed", "username and password do not match")
			return false
	print("Server: Succesful Login")
	return true

remote func server_validate_login(id, user, passwd):
	print("Server: Validating client ", str(id))
	if validate_user(id, user, passwd):
		load_player_server(id, user, players[user].spawn)
		rpc_id(id, "load_world", players[user].spawn)
		rpc_id(id, "load_player", id, user, players[user].spawn)
		for i in current.keys():
			rpc_id(i, "load_player", id, user, players[user].spawn)
			rpc_id(id, "load_player", i, current[i].name, current[i].spawn)
		current[id] = {'id': id, 'name': user, 'spawn': players[user].spawn}

func load_world_server():
	print("Server: loading world")
	var world = preload("res://server/ServerWorld.tscn").instance()
	world.name = "World"
	get_node(".").add_child(world)

func load_player_server(id, username, origin):
	print("Server: loading player ", username)
	var this_player = preload("res://server/ServerPlayer.tscn").instance()
	this_player.set_name(str(id))
	this_player.position = origin
	this_player.set_network_master(id)
	get_node("./World").call_deferred("add_child", this_player)
