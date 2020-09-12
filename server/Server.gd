extends Node2D

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

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
# actor_map = { Vector2: { int: Node } }
# actor_map[Vector2(0, 0)][12345] = get_node("Player")
# var stats_object = get_stats_obj(actor_map[Vector2(0, 0)][12345])
var actor_map := {}
# Holds all monster coordinates
# monster_map = { Vector2: { str: NodeReference } }
# monster_map[Vector2(0, 0)] = { monster.name: monster }
# will use stats obj after they are reintroduced
var monster_map := {}

# Called when the node enters the scene tree for the first time.
func _enter_tree():
	init_server()

func init_server():
	var tree = get_tree()
	var peer = NetworkedMultiplayerENet.new()
	tree.connect("network_peer_connected", self, "_client_connect")
	tree.connect("network_peer_disconnected", self, "_client_disconnect")
	peer.create_server(Global.server_port, MAX_PLAYERS)
	load_world_server()
	tree.network_peer = peer
	print("Server: READY")

func _client_connect(id):
	if current.size() == MAX_PLAYERS:
		print("Server: Too many players, can't fit ", id)
#	print("Server: Client ", str(id), " connected")

func _client_disconnect(id):
	print("Server: Client ", str(id), " left")
	if not current.has(id):
		print("Server: Not a current player")
		return
	var c = current[id]
	if not current.erase(id):
		print("Server: erase(id): not erased")
	var deadClient = get_node("./World/" + str(id))
	if deadClient == null:
		print("Server: Not a node in tree")
		return
	players[c.name].spawn = deadClient.position
# warning-ignore:unsafe_method_access
	get_node("World").remove_dead_actor(id, deadClient.coords)
	deadClient.queue_free()

func validate_user(id, user, passwd):
	if not players.has(user):
		print("Server: New Player: ", user, " as ", id)
		players[user] = {'passwd': hash(passwd), 'spawn': Global.origin}
	else:
		if current.has(user):
			print("Server: ", user, " is attempting to log in twice")
			rpc_id(id, "client_login_failed", "You can't log in twice")
			return false
		if players[user].passwd != hash(passwd):
			print("Server: Bad login")
			rpc_id(id, "client_login_failed", "Invalid username or passrod")
			return false
	return true

remote func server_validate_login(id, user, passwd):
	if validate_user(id, user, passwd):
		var spawn = players[user].spawn
		load_player_server(id, user, spawn)
		rpc_id(id, "load_world", spawn)
		rpc_id(id, "load_player", id, user, spawn, 100, 100, 11, 10, 12, 15, 13, 9)
		current[id] = {'id': id, 'name': user, 'spawn': spawn}

func load_world_server():
	print("Server: loading world")
	var world = preload("res://server/ServerWorld.tscn").instance()
	world.name = "World"
	get_node(".").add_child(world)

func load_player_server(id, username, spawn):
#	print("Server: loading player ", username)
	var this_player = preload("res://server/ServerPlayer.tscn").instance()
	this_player.set_name(str(id))
	this_player.position = spawn
	this_player.rset_config('position', 1)
	this_player.set_network_master(id)
	this_player.actor_map = actor_map
	this_player.username = username
	this_player.max_hp = 100
	this_player.hp = 100
	var world = get_node("./World")
	world.actor_map = actor_map
	world.monster_map = monster_map
	world.call_deferred("add_child", this_player)
