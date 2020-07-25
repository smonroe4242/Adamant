extends Node2D
const level = preload("res://game/NoiseLevel.tscn")
const offset = Global.offsetv
const size = Global.chunk_size
var simplex = OpenSimplexNoise.new()
var chunks = {}
var origin = Vector2(0, 0)
enum biome {Underworld, Ground, Overworld}

func _ready():
	make_noise()
	respawn(origin)

func respawn(rsp):
	gen_block(Vector2(int(rsp.x / offset.x), int(rsp.y / offset.y)))

# initialize OpenSimplexNoise parameters
func make_noise():
	simplex.set_seed(13)
	simplex.set_lacunarity(2.0)
	simplex.set_octaves(1)
	simplex.set_period(10.0)
	simplex.set_persistence(1)

func gen_chunk(v):
	if v in chunks.keys():
		return
	var lvl = level.instance()
	lvl.type = biome.Underworld if v.y > 0 else biome.Ground if v.y == 0 else biome.Overworld
	lvl.position = (v * offset) - Vector2(Global.tile_size, Global.tile_size)
	lvl.coords = v
	lvl.ref = v * Vector2(size, size)
	lvl.simplex = simplex
	chunks[v] = lvl
	call_deferred("add_child", lvl)

remote func load_actors(actors):
	if not actors == null:
		for actor in actors:
			load_actor(actor.id, actor.user)

remote func load_actor(id, username):
	if not get_node(str(id)) == null:
		print("Client: load_actor(): player ", id, " already in tree")
	print("Loading ", username)
	var this_player = preload("res://game/Player.tscn").instance()
	this_player.set_name(str(id))
	this_player.set_display_name(username)
	this_player.set_network_master(1)
	this_player.get_node("Camera2D").current = false
	call_deferred("add_child", this_player)

func kill_chunk(v):
	if not chunks.has(v):
		return
	chunks[v].queue_free()
	chunks.erase(v)

remote func unload_actors(actors):
	if not actors == null:
		for id in actors:
			unload_actor(id)

remote func unload_actor(id):
	var deadActor = get_node(str(id))
	if not deadActor == null:
		deadActor.queue_free()
	else:
		print("Client: unload_actor(): dA was null")

func gen_block(v):
	var block = Global.get_area(v)
	for chunk in block:
		gen_chunk(chunk)
	for chunk in chunks.keys():
		if not chunk in block:
			kill_chunk(chunk)

remote func load_monsters(names, chunk):
	if not names == null:
		for node_name in names:
			load_monster(node_name, chunk.y)

remote func load_monster(node_name, level):
	var mob = preload("res://game/Monster.tscn").instance()
	mob.displayName = "Big Dark Boi LVL" + str(level)
	mob.level = level
	mob.name = node_name
	mob.set_network_master(1)
	call_deferred("add_child", mob)

remote func unload_monsters(names):
	if not names == null:
		for name in names:
			unload_monster(name)

remote func unload_monster(monster_name):
	var monster = get_node(monster_name)
	if not monster == null:
		monster.queue_free()

func player_entered(old_coords, new_coords, username):
	rpc_id(1, "update_player_coords", old_coords, new_coords, username)
	gen_block(new_coords)
