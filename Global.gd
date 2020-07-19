extends Node2D

const server_port := 8910
const chunk_size := 32 # tiles per chunk
const tile_size := 64 # pixels per tile
const chunk_offset := chunk_size * tile_size
const offsetv := Vector2(chunk_offset, chunk_offset)
# warning-ignore:unused_class_variable
var server_ip := ""
# warning-ignore:unused_class_variable
var username := ""
# warning-ignore:unused_class_variable
var password := ""
# warning-ignore:unused_class_variable
var error := ""
# warning-ignore:unused_class_variable
var player_node = null
