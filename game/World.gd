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
	simplex.set_period(7.0)
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
			load_actor(actor)

remote func load_actor(stats):#id, username, pos, mhp, hp):
	print("Client: load_actor: ", stats)
	if not get_node(str(stats.id)) == null:
		print("Client: load_actor(): player ", stats.id, " already in tree")
		return
	print("Client: Loading ", stats.user)
	var this_player = preload("res://game/Player.tscn").instance()
	set_stats_obj(this_player, stats)
	add_child(this_player)

func set_stats_obj(node, stats):
	node.set_name(str(stats.id))
	node.set_display_name(stats.user)
	node.position = stats.position
	node.animation = stats.animation
	node.max_hp = stats.max_hp
	node.hp = stats.hp
	node.blocking = stats.blocking
	node.classtype = stats.classtype
	node.get_node("Camera2D").current = false
	node.set_network_master(1)

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
	mob.displayName = "BigBoi LVL" + str(level)
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
