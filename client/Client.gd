extends Node2D
# Called when the node enters the scene tree for the first time.
func _enter_tree():
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
	peer.create_client(Global.server_ip, Global.server_port)
	tree.network_peer = peer
	print("READY")

func _server_connect():
	print("Client: server connected")
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
	rpc_id(1, "server_validate_login", get_tree().get_network_unique_id(), Global.username, Global.password)

func _server_connect_fail():
	print("Client: server connect failed")

func _server_disconnect():
	print("Client: server disconnected")

remote func client_login_failed(err):
	print("Client: Login failed for player: ", str(err))
	if not get_tree().change_scene("res://client/Login.tscn"):
		print("Error changing scene to Login")

remote func remove_player(id):
	print("removing player ", id)
	var parent = get_node("./World")
	var deadClient = parent.get_node(str(id))
	if not deadClient == null:
		deadClient.queue_free()

remote func load_world(origin):
	var world = preload("res://game/World.tscn").instance()
	world.origin = origin
	get_node(".").add_child(world)

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
		Global.player_node = this_player
	else: # client replica
		this_player.set_network_master(1)
		this_player.get_node("Camera2D").current = false
	get_node("./World").call_deferred("add_child", this_player)
