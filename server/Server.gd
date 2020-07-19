extends Node2D

const MAX_PLAYERS = 200
# Holds all players who have ever logged in
# players = { str: { int, Vector2 } }
# players[username] = {'passwd': hash(passwd), 'spawn': Vector2(0, 0)}
var players := {}
# Holds all players currently logged in
# current = { int: { int, str, Vector2 } }
# current[id] = {'id': id, 'name': username, 'spawn': players[username].spawn}
var current := {}
# Holds all players coordinates
# actor_map = { Vector2: { int: { int, str } } }
# actor_map[Vector2(0, 0)][12345] = {id: 12345, user: "Player1"}
var actor_map := {}

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
	if current.get(id) == null:
		print("Not a current player")
		return
	var c = current[id]
	if not current.erase(id):
		print("erase(id): not erased")
	else:
		print("erase(id) erased")
	var deadClient = get_node("./World/" + str(id))
	if deadClient == null:
		print("Not a node in tree")
		return
	players[c.name].spawn = deadClient.position
# warning-ignore:unsafe_method_access
	get_node("./World").remove_dead_actor(deadClient.coords, id)
	deadClient.queue_free()
	for i in current:
		rpc_id(i, "remove_player", id)
	print("Server: removing player ", id)

func validate_user(id, user, passwd):
	if players.get(user) == null:
		print("Server: New Player: ", user, " as ", id)
		players[user] = {'passwd': hash(passwd), 'spawn': Vector2(0, 0)}
	else:
		if not current.get(user) == null:
			print("Server: ", user, " is attempting to log in twice")
			rpc_id(id, "client_login_failed", "You can't log in twice")
			return false
		if players[user].passwd != hash(passwd):
			print("Server: Bad login")
			rpc_id(id, "client_login_failed", "Invalid username or passrod")
			return false
	print("Server: Succesful Login for ", user)
	return true

remote func server_validate_login(id, user, passwd):
	print("Server: Validating client ", str(id))
	if validate_user(id, user, passwd):
		load_player_server(id, user, players[user].spawn)
		rpc_id(id, "load_world", players[user].spawn)
		rpc_id(id, "load_player", id, user, players[user].spawn)
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
	var world = get_node("./World")
	world.actor_map = actor_map
	world.call_deferred("add_child", this_player)
