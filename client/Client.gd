extends Node2D
# Called when the node enters the scene tree for the first time.
func _enter_tree():
	init_client()

func init_client():
	print("CLIENT")
	var tree = get_tree()
#	tree.set_debug_collisions_hint(true)
	var peer = NetworkedMultiplayerENet.new()
	tree.connect("connected_to_server", self, "_server_connect")
	tree.connect("connection_failed", self, "_server_connect_fail")
	tree.connect("server_disconnected", self, "_server_disconnect")
	var err = peer.create_client(Global.server_ip, Global.server_port)
	if err:
		client_login_failed(err)
	tree.network_peer = peer
	print("READY")

func _server_connect():
	print("Client: server connected")
	rpc_id(1, "server_validate_login", get_tree().get_network_unique_id(), Global.username, Global.password)

func _server_connect_fail():
	print("Client: server connect failed")
	client_login_failed("Failed to connect to realm")

func _server_disconnect():
	print("Client: server disconnected")
	client_login_failed("Disconnected from realm")

remote func client_login_failed(err):
	print("Client: Login failed")
	if TYPE_INT == typeof(err):
		Global.error = print_err_string(err, true)
	else:
		Global.error = err
	if not get_tree().change_scene("res://client/Login.tscn"):
		print("Error changing scene to Login")
	else:
		print("Success changing to Login")

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
		this_player.connect("player_entered", get_node("./World"), "player_entered")
		Global.player_node = this_player
	else: # client replica
		this_player.set_network_master(1)
		this_player.get_node("Camera2D").current = false
	get_node("./World").call_deferred("add_child", this_player)

func print_err_string(err, to_print = true):
	var msg = [
	'Everything is fine.',
	'Generic error.',
	'Unavailable.',
	'Unconfigured.',
	'Unauthorized.',
	'Parameter range error.',
	'Out of memory (OOM).',
	'File: Not found.',
	'File: Bad drive.',
	'File: Bad path.',
	'File: No permission.',
	'File: Already in use.',
	'File: Can\'t open.',
	'File: Can\'t write.',
	'File: Can\'t read.',
	'File: Unrecognized.',
	'File: Corrupt.',
	'File: Missing dependencies.',
	'File: End of file (EOF).',
	'Can\'t open.',
	'Can\'t create resource.',
	'Query failed.',
	'Already in use.',
	'Locked.',
	'Timeout.',
	'Can\'t connect.',
	'Can\'t resolve host.',
	'Connection error.',
	'Can\'t acquire resource.',
	'Can\'t fork process.',
	'Invalid data.',
	'Invalid parameter.',
	'Already exists.',
	'Does not exist.',
	'Database: Read error.',
	'Database: Write error.',
	'Compilation failed.',
	'Method not found.',
	'Linking failed.',
	'Script failed.',
	'Cycling link (import cycle) error.',
	'Invalid declaration.',
	'Duplicate symbol.',
	'Parse error.',
	'Busy error.',
	'Skip error.',
	'Help error.',
	'Bug error.',
	'Printer on fire.'
	]
	var code = [
	'OK',
	'FAILED',
	'ERR_UNAVAILABLE',
	'ERR_UNCONFIGURED',
	'ERR_UNAUTHORIZED',
	'ERR_PARAMETER_RANGE_ERROR',
	'ERR_OUT_OF_MEMORY',
	'ERR_FILE_NOT_FOUND',
	'ERR_FILE_BAD_DRIVE',
	'ERR_FILE_BAD_PATH',
	'ERR_FILE_NO_PERMISSION',
	'ERR_FILE_ALREADY_IN_USE',
	'ERR_FILE_CANT_OPEN',
	'ERR_FILE_CANT_WRITE',
	'ERR_FILE_CANT_READ',
	'ERR_FILE_UNRECOGNIZED',
	'ERR_FILE_CORRUPT',
	'ERR_FILE_MISSING_DEPENDENCIES',
	'ERR_FILE_EOF',
	'ERR_CANT_OPEN',
	'ERR_CANT_CREATE',
	'ERR_QUERY_FAILED',
	'ERR_ALREADY_IN_USE',
	'ERR_LOCKED',
	'ERR_TIMEOUT',
	'ERR_CANT_CONNECT',
	'ERR_CANT_RESOLVE',
	'ERR_CONNECTION_ERROR',
	'ERR_CANT_ACQUIRE_RESOURCE',
	'ERR_CANT_FORK',
	'ERR_INVALID_DATA',
	'ERR_INVALID_PARAMETER',
	'ERR_ALREADY_EXISTS',
	'ERR_DOES_NOT_EXIST',
	'ERR_DATABASE_CANT_READ',
	'ERR_DATABASE_CANT_WRITE',
	'ERR_COMPILATION_FAILED',
	'ERR_METHOD_NOT_FOUND',
	'ERR_LINK_FAILED',
	'ERR_SCRIPT_FAILED',
	'ERR_CYCLIC_LINK',
	'ERR_INVALID_DECLARATION',
	'ERR_DUPLICATE_SYMBOL',
	'ERR_PARSE_ERROR',
	'ERR_BUSY',
	'ERR_SKIP',
	'ERR_HELP',
	'ERR_BUG',
	'ERR_PRINTER_ON_FIRE'
	]
	var error
	if err > -1 and err < code.size():
		error = code[err] + ": " + msg[err]
	else:
		error = 'UNKNOWN ENGINE ERROR: This is not a known error code, please contact a developer.'
	if to_print:
		print(error)
	return error
