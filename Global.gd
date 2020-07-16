extends Node2D

const chunk_size = 16 # tiles per chunk
const tile_size = 64 # pixels per tile
const chunk_offset = chunk_size * tile_size
# warning-ignore:unused_class_variable
export var username = ""
# warning-ignore:unused_class_variable
export var password = ""
# warning-ignore:unused_class_variable
export var server_ip = ""
var player_node = null
