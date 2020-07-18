extends Node2D
const level = preload("res://game/NoiseLevel.tscn")
const offset = Global.offsetv
const size = Global.chunk_size
var simplex = OpenSimplexNoise.new()
var chunks = {}
var origin = Vector2(0, 0)
enum biome {SKY, OVERWORLD, CAVE}

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
	lvl.type = biome.OVERWORLD if v.y == 0 else biome.CAVE if v.y > 0 else biome.SKY
	lvl.position = v * offset
	lvl.coords = v
	lvl.ref = v * Vector2(size, size)
	lvl.size = size
	lvl.simplex = simplex
	chunks[v] = lvl
	call_deferred("add_child", lvl)

remote func load_local_actors(actors, chunk):
	if not actors == null:
#		print("actors received to load:")
		for actor in actors.values():
#			print(actor.user)
			load_actor(actor.id, actor.user, chunk)

remote func load_actor(id, username, chunk):
	if not get_node(str(id)) == null:
#		print("Client: load_actor(): player ", id, " already in tree")
		return
	print("Loading ", username)
	var this_player = preload("res://game/Player.tscn").instance()
	this_player.set_name(str(id))
	this_player.set_display_name(username)
	this_player.coords = chunk
	this_player.position = Vector2(0, 0)
	this_player.set_network_master(1)
	this_player.get_node("Camera2D").current = false
	call_deferred("add_child", this_player)

func kill_chunk(v):
	if not v in chunks.keys():
		return
	chunks[v].queue_free()
	chunks.erase(v)

remote func unload_local_actors(actors):
	if not actors == null:
#		print("actors received for unload:")
		for id in actors.keys():
			print("Unloading ", actors[id].user)
			unload_actor(id)

remote func unload_actor(id):
#	print("Client: unload_actor ", id)
	var deadActor = get_node(str(id))
	if not deadActor == null:
		deadActor.queue_free()

func gen_block(v):
	var block = get_borderv(v)
	for chunk in block:
		gen_chunk(chunk)
	for chunk in chunks.keys():
		if not chunk in block:
			kill_chunk(chunk)

func player_entered(old_coords, new_coords, username):
	rpc_id(1, "update_player_coords", old_coords, new_coords, username)
	gen_block(new_coords)

func get_borderv(v):
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

#func get_big_borderv(v):
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
