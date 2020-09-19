extends Node2D
# warning-ignore-all:unused_class_variable
const server_port := 49152 # Port that game traffic goes through
const tile_size := 16 # Pixel width of a tile
const chunk_size := 64 # Tile wdith of a chunk
const chunk_offset := chunk_size * tile_size # Pixel width of a chunk
const offsetv := Vector2(chunk_offset, chunk_offset) # Pixel offset of a chunk
const origin = offsetv + Vector2(64, -64) # Pixel coords of a new player's login spawn
var server_ip := ""
var username := ""
var password := ""
var error := ""
var player_node = null
var character_name = ""

var class_strings = [
	"Warrior",
	"Archer",
	"Wizard"
]

func get_area(v):
	return [
		v,
		v + Vector2.UP,
		v + Vector2.DOWN,
		v + Vector2.LEFT,
		v + Vector2.RIGHT,
		v + Vector2(-1, -1),#Vector2.UP + Vector2.LEFT,
		v + Vector2(1, -1),#Vector2.UP + Vector2.RIGHT,
		v + Vector2(-1, 1),#Vector2.DOWN + Vector2.LEFT,
		v + Vector2(1, 1),#Vector2.DOWN + Vector2.RIGHT,
		]

func get_area_around(v):
	return [
		v + Vector2.LEFT,
		v + Vector2.RIGHT,
		v + Vector2.UP,
		v + Vector2.DOWN,
		v + Vector2(-1, -1),#Vector2.UP + Vector2.LEFT,
		v + Vector2(1, -1),#Vector2.UP + Vector2.RIGHT,
		v + Vector2(-1, 1),#Vector2.DOWN + Vector2.LEFT,
		v + Vector2(1, 1),#Vector2.DOWN + Vector2.RIGHT,
		]

#func get_big_area(v):
#	return [
#		v,
#		v + Vector2.UP,
#		v + Vector2.UP + Vector2.UP,
#		v + Vector2.UP + Vector2.UP + Vector2.LEFT,
#		v + Vector2.UP + Vector2.UP + Vector2.LEFT + Vector2.LEFT,
#		v + Vector2.UP + Vector2.UP + Vector2.RIGHT,
#		v + Vector2.UP + Vector2.UP + Vector2.RIGHT + Vector2.RIGHT,
#		v + Vector2.DOWN,
#		v + Vector2.DOWN + Vector2.DOWN,
#		v + Vector2.DOWN + Vector2.DOWN + Vector2.LEFT,
#		v + Vector2.DOWN + Vector2.DOWN + Vector2.LEFT + Vector2.LEFT,
#		v + Vector2.DOWN + Vector2.DOWN + Vector2.RIGHT,
#		v + Vector2.DOWN + Vector2.DOWN + Vector2.RIGHT + Vector2.RIGHT,
#		v + Vector2.LEFT,
#		v + Vector2.LEFT + Vector2.LEFT,
#		v + Vector2.LEFT + Vector2.LEFT + Vector2.UP,
#		v + Vector2.LEFT + Vector2.LEFT + Vector2.DOWN,
#		v + Vector2.RIGHT,
#		v + Vector2.RIGHT + Vector2.RIGHT,
#		v + Vector2.RIGHT + Vector2.RIGHT + Vector2.UP,
#		v + Vector2.RIGHT + Vector2.RIGHT + Vector2.DOWN,
#		v + Vector2.UP + Vector2.LEFT,
#		v + Vector2.UP + Vector2.RIGHT,
#		v + Vector2.DOWN + Vector2.LEFT,
#		v + Vector2.DOWN + Vector2.RIGHT,
#		]
func set_err_msg(err, to_print = true):
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
	var header = "Server: " if get_tree().is_network_server() else "Client: "
	if err > -1 and err < code.size():
		error = code[err] + ": " + msg[err]
	else:
		error = 'UNKNOWN ENGINE ERROR: This is not a known error code, please contact a developer.'
	if to_print:
		print(header + error)
