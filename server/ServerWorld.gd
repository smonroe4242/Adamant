extends Node2D
# Please read this, it will save you much of my pain.
# Dictionary notes to keep in mind since this is a complex file and dicts are all we do here:
# {"name": "Bob"}.erase("Bob") doesn't work, only takes keys, and will return false
# {"name": "Bob"}.erase("name") will return true because the key was found
# {"name": "Bob"}.erase("adamant") will return false because the key wasn't found
# for i in my_dict: iterates through values, so .values() is redundant and .keys() is useful
# for i in my_dict.keys(): my_dict.erase() leads to undefined behavior as per godot docs, DO NOT ERASE KEYS WHILE ITERATING
# Dictionaries are ALWAYS passed by reference, {}.duplicate to make a one-level deep copy by value
# {}.duplicate(true) will recursively copy everything by value except for Nodes, which will just be referenced

# actor_map[coord][net_id] = {id: net_id, user: username}
var actor_map
# monster_map[coord] = { m.name: m }
var monster_map

func remove_dead_actor(actor_id, coords): # Can this be used for both disconnects and respawns?
# Given a user and a chunk
#   Tell all players that player is gone
#   If there are monsters that are now unseen
#     Remove monsters from server
	# First, we remove the player from record keeping
	if not actor_map.has(coords):
		var real_coords = null
		print("Server: remove_dead_actor(): params are not sane, actor_map[", coords, "] is not an entry.")
		for chunk in Global.get_area_around(coords):
			if actor_map.has(chunk):
				if actor_map[chunk].has(actor_id):
					real_coords = chunk
					break
		if  real_coords == null:
			print("Server: remove_dead_actor(): actor could not be found, exiting early.")
			print("ActorMap: ", actor_map)
			return
		print("ActorMap: ", actor_map)
		coords = real_coords
	if not actor_map[coords].erase(actor_id):
		print("Server: remove_dead_actor(): failed actor_map[", coords, "].erase(", actor_id, ")")
	if actor_map[coords].empty():
		if not actor_map.erase(coords):
			print("Server: remove_dead_actor(): failed actor_map.erase(", coords, ")")
	# Then, we search the area of other players
	for chunk in Global.get_area(coords):
		if actor_map.has(chunk):
			# This chunk has other players, so we tell them somebody left
			print("SERVER: unloading actor ", actor_id, " from ", actor_map[chunk].keys())
			for player in actor_map[chunk].keys():
				rpc_id(player, "unload_actor", actor_id)
		elif monster_map.has(chunk):
		# This is commented out and partially implemented in despawn_monsters
		# Likely we will add 5x5 search on chunk exit using a cache system to avoid
		# redundant chunk checks for neighboring monster filled cells
			# This chunk doesn't have players, but it does have monsters
		#	var observed = false
			# We check to see if anyone can see the monsters
		#	for area in Global.get_area_around(chunk):
		#		if actor_map.has(area):
					# Somebody is watching!
		#			observed = true
		#			break
		#	if not observed:
				# We didn't find anyone to observe the monster, so it must not exist
				despawn_monsters(chunk)

remote func get_local_actors(coords, username):
	var actor_id = get_tree().get_rpc_sender_id()
	for chunk in Global.get_area(coords):
		if chunk in actor_map.keys():
			# There are already players here
			send_players(actor_id, username, chunk)
			if chunk in monster_map.keys():
				# There are already monsters too
				send_monsters(actor_id, chunk)
		else:
			if not chunk in monster_map.keys():
				# There are no monsters or players
				spawn_monsters(chunk)
			send_monsters(actor_id, chunk)
	if not actor_map.has(coords):
		actor_map[coords] = {}
	actor_map[coords][actor_id] = {'id': actor_id, 'user': username}

remote func update_player_coords(old_coords, new_coords, username):
#	print("UpdatePlayerCoords Entry Params: old_coords: ", old_coords, ", new_coords: ", new_coords, ", username: ", username)
#	print("ACTOR_MAP:")
#	print(actor_map)
#	print("MONSTER_MAP Before:")
#	print(monster_map)
	var actor_id = get_tree().get_rpc_sender_id()
	var old_area = Global.get_area(old_coords)
	var new_area = Global.get_area(new_coords)
# Move user's record, must happen before despawn_monsters is called
	if not actor_map.has(new_coords):
		actor_map[new_coords] = {}
	actor_map[new_coords][actor_id] = actor_map[old_coords][actor_id]
	actor_map[old_coords].erase(actor_id)
#	print("Player should now be here: ", actor_map[new_coords])
#	print("Player should no longer be here: ", actor_map[old_coords])
	if actor_map[old_coords].empty():
		if not actor_map.erase(old_coords):
			print("Server: somehow actor_map[", old_coords, "] was not found")
# Handle newly loaded areas and actors
	for chunk in new_area:
		if not chunk in old_area:
		# Newly loaded tile
			if actor_map.has(chunk):
				# There are already players here
				send_players(actor_id, username, chunk)
				if monster_map.has(chunk):
					# There are already monsters too
					send_monsters(actor_id, chunk)
				# and we don't spawn monsters when players are already here
			else:
				if not monster_map.has(chunk):
				# There are no monsters or players, so we spawn monsters
					spawn_monsters(chunk)
				send_monsters(actor_id, chunk)
# Handle unloaded areas and actors
	for chunk in old_area:
		if not chunk in new_area:
		# Unloaded tile
			if actor_map.has(chunk):
				# Someone is still here
				unload_players(actor_id, chunk)
				if monster_map.has(chunk):
					# Unload monsters from client, but keep on server
					unload_monsters(actor_id, chunk)
			elif monster_map.has(chunk):
				# No players left, but still monsters, so unload from client and server
				unload_monsters(actor_id, chunk)
				# TODO if another player is just over the chunk line, the monsters despawns in view of them, e.g.:
				# OOOUOO where O is empty chunk, M is a monster chunk, U is being unloaded
				# ONLMPO N is the new chunk a player walked to, L is where they came from
				# OOOUOF and P and F are other players
				# column UMU is unloaded, so we'll try to despawn the monster in M
				# but P could be a few tiles away, maybe fighting it when it despawns
				# however, F can't see it
				# so, we need to check a 5x5 grid around L to be safe.
				# we'll need the remove_dead_actor level of logic here
				# We can implement caching with Global.get_big_area(chunk) to not recheck cells, taking us from 72 monster chunk checks to 25, not bad.
				# Currently, despawn_monsters just checks the 9 chunk area around, we'll improve it when we need to.
				despawn_monsters(chunk)
#	print("#################### UpdatePlayerCoords Part1 #######################################")
#	print("ACTOR_MAP:")
#	print(actor_map)
#	print("MONSTER_MAP After:")
#	print(monster_map)

func send_players(actor_id, username, chunk):
#	print("send_players(", actor_id, ", ", username, ", ", chunk, "): ", actor_map[chunk].keys())
# Given a user and a chunk:
#   Tell the user about every player in the chunk
#   Tell every player in the chunk about the user
	for player in actor_map[chunk].keys():
		rpc_id(player, "load_actor", actor_id, username)
	rpc_id(actor_id, "load_actors", actor_map[chunk].values())
func unload_players(actor_id, chunk):
#	print("unload_players(", actor_id, ", ", chunk, "): ", actor_map[chunk].keys())
# Given a user and a chunk
#   Tell every player in the chunk to unload the user
#   Tell the user to unload every player in the chunk
	for player in actor_map[chunk].keys():
		rpc_id(player, "unload_actor", actor_id)
	rpc_id(actor_id, "unload_actors", actor_map[chunk].keys())
func spawn_monsters(chunk):
#	print("spawn_monsters(", chunk, ")")
# Given a chunk
#   Create a monster on the server
#	if chunk.x < 1 or chunk.y < 1:
#		return
	var mob = preload("res://server/ServerMonster.tscn").instance()
	mob.set_network_master(1)
	mob.actor_map = actor_map
	mob.monster_map = monster_map
	mob.coords = chunk
	mob.position = chunk * Global.offsetv
	mob.name = "M" + str(mob.get_instance_id())
	mob.level = chunk.y
	mob.max_hp = chunk.y * 100
	mob.hp = mob.max_hp
	if not chunk in monster_map:
		monster_map[chunk] = {}
	call_deferred("add_child", mob)
	if not monster_map.has(chunk):
		monster_map[chunk] = {}
	monster_map[chunk][mob.name] = mob
func send_monsters(actor_id, chunk):
#	print("send_monsters(", actor_id, ", ", chunk, "): ", monster_map[chunk])
# Given a user and a chunk
#   Tell the user about every monster in the chunk
	if monster_map.has(chunk):
		rpc_id(actor_id, "load_monsters", monster_map[chunk].keys(), chunk)
	else:
		print("Server: send_monsters(): ", chunk, " not found in monster_map")
		print("Server: MonsterMap: ", monster_map)
func unload_monsters(actor_id, chunk):
#	print("unload_monsters(", actor_id, ", ", chunk, "): ", monster_map[chunk])
# Given a user and a chunk
#   Tell the user to unload every monster in the chunk
	if monster_map.has(chunk):
		rpc_id(actor_id, "unload_monsters", monster_map[chunk].keys())
	else:
		print("Server: unload_monsters(): ", chunk, " not found in monster_map")
		print("Server: MonsterMap: ", monster_map)

func despawn_monsters(chunk):
#	print("despawn_monsters(", chunk, "): ", monster_map[chunk])
# Given a chunk
#   Remove every monster in the chunk from the server
#   But only if nobody can see it
	if not monster_map.has(chunk):
		print("Server: unload_monsters(): ", chunk, " not found in monster_map")
		print("MonsterMap: ", monster_map)
#	print("Server: despawn_monsters(): monster_map[chunk]: ", monster_map[chunk])
	var observed = false
	for area in Global.get_area(chunk):
		if actor_map.has(area):
			observed = true
			break
	if not observed:
		for monster in monster_map[chunk].values():
	#		print("Server: despawn_monsters(): monster: ", monster)
			monster.queue_free()
		monster_map.erase(chunk)
