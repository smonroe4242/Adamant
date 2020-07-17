extends Node2D

# Holds all players coordinates
var actor_map := {}
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

remote func update_player_coords(coords):
#	var net_id = get_tree().get_rpc_sender_id()
#	if actor_map[coords] == null:
#		actor_map[coords] = []
#	actor_map[coords].append(net_id)
	print(get_tree().get_rpc_sender_id(), ": ", coords)
	pass
