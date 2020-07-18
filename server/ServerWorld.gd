extends Node2D

var actor_map
# Called when the node enters the scene tree for the first time.
func get_area(v):
	return [
		v,
		v + Vector2.UP,
		v + Vector2.DOWN,
		v + Vector2.LEFT,
		v + Vector2.RIGHT,
		v + Vector2.UP + Vector2.LEFT,
		v + Vector2.UP + Vector2.RIGHT,
		v + Vector2.DOWN + Vector2.LEFT,
		v + Vector2.DOWN + Vector2.RIGHT,
		]

func get_area_around(v):
	return [
		v + Vector2.LEFT,
		v + Vector2.RIGHT,
		v + Vector2.UP,
		v + Vector2.DOWN,
		v + Vector2.UP + Vector2.LEFT,
		v + Vector2.UP + Vector2.RIGHT,
		v + Vector2.DOWN + Vector2.LEFT,
		v + Vector2.DOWN + Vector2.RIGHT,
		]

func remove_dead_actor(coords, id):
#	print("ServerWorld: REMOVING ", id, ": ", coords)
	if actor_map.get(coords) == null:
		print("THIS SHOULD NEVER HAPPEN, but it can on a dirty well timed disconnect")
	else:
		for a_id in actor_map[coords].keys():
			rpc_id(a_id, "unload_actor", id)
		if not actor_map[coords].erase(id):
			print("Server: RM LOCATION CORRUPTION : [", id, "] not erased from ", coords, " on logout")
		else:
			return

	for chunk in get_area_around(coords):
		if actor_map.get(chunk):
			for a_id in actor_map[chunk].keys():
				if id != a_id:
					rpc_id(a_id, "unload_actor", id)
			if actor_map[chunk].get(id) != null:
#				print("found player here")
				if not actor_map[chunk].erase(id):
					print("Server: LOCATION CORRUPTION : [", id, "] not erased from ", coords, "  on logout after failing once before")
				elif actor_map[chunk].empty:
#					print("Finally got them, doing empty chunk cleanup")
					actor_map.erase(chunk)
#				else:
#					print("Finally got them, and stale chunk entry removed gracefully")

remote func update_player_coords(old_coords, new_coords, username):
	# Get network id of sender and ensure space allocated in actor_map
	var actor_id = get_tree().get_rpc_sender_id()
#	print("ServerWorld: Update and Notify All: ", actor_id, " at ", new_coords)
	if actor_map.get(new_coords) == null:
		actor_map[new_coords] = {}

	# Make updated entry in actor_map
	actor_map[new_coords][actor_id] = {'id': actor_id, 'user': username}
	# Remove old coords entry
	# Make sure one exists
	if actor_map.get(old_coords):
		# Erase if found
		if not actor_map[old_coords].erase(actor_id):
			print("Server: LOCATION CORRUPTION : [", actor_id, "]:\"", username, "\" not erased from ", old_coords, " after moving to ", new_coords)
		# Clear coord entry if its the last one
		elif actor_map[old_coords].empty():
#			print("empty chunk cleanup")
			actor_map.erase(old_coords)

	# Tell everyone about their new neighbors
	for neighbor in get_area_around(new_coords):
		if actor_map.get(neighbor):
			for id in actor_map[neighbor].keys():
				# Tell all inhabitants of neighboring chunks player is here
				rpc_id(id, "load_actor", actor_id, username, new_coords)
			# Tell player about all neighboring actors
			rpc_id(actor_id, "load_local_actors", actor_map[neighbor], neighbor)

	# Remove neighbors that moved away
	var old_chunks = get_area(old_coords)
	var new_chunks = get_area(new_coords)
	for chunk in old_chunks:
		if not chunk in new_chunks and actor_map.get(chunk):
			# This was a chunk unloaded by player
#			print("SERVER: removing player from ", chunk)
			# Tell player to unload its actors
			rpc_id(actor_id, "unload_local_actors", actor_map[chunk])
			for id in actor_map[chunk].keys():
				if id != actor_id:
					# Tell each player to remove the player
					rpc_id(id, "unload_actor", actor_id)
