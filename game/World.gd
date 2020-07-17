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

func kill_chunk(v):
	if not v in chunks.keys():
		return
	chunks[v].queue_free()
	chunks.erase(v)

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

func get_big_borderv(v):
	return [
		v,
		v + Vector2.UP,
		v + Vector2.UP + Vector2.UP,
		v + Vector2.UP + Vector2.UP + Vector2.LEFT,
		v + Vector2.UP + Vector2.UP + Vector2.LEFT + Vector2.LEFT,
		v + Vector2.UP + Vector2.UP + Vector2.RIGHT,
		v + Vector2.UP + Vector2.UP + Vector2.RIGHT + Vector2.RIGHT,
		v + Vector2.DOWN,
		v + Vector2.DOWN + Vector2.DOWN,
		v + Vector2.DOWN + Vector2.DOWN + Vector2.LEFT,
		v + Vector2.DOWN + Vector2.DOWN + Vector2.LEFT + Vector2.LEFT,
		v + Vector2.DOWN + Vector2.DOWN + Vector2.RIGHT,
		v + Vector2.DOWN + Vector2.DOWN + Vector2.RIGHT + Vector2.RIGHT,
		v + Vector2.LEFT,
		v + Vector2.LEFT + Vector2.LEFT,
		v + Vector2.LEFT + Vector2.LEFT + Vector2.UP,
		v + Vector2.LEFT + Vector2.LEFT + Vector2.DOWN,
		v + Vector2.RIGHT,
		v + Vector2.RIGHT + Vector2.RIGHT,
		v + Vector2.RIGHT + Vector2.RIGHT + Vector2.UP,
		v + Vector2.RIGHT + Vector2.RIGHT + Vector2.DOWN,
		v + Vector2.UP + Vector2.LEFT,
		v + Vector2.UP + Vector2.RIGHT,
		v + Vector2.DOWN + Vector2.LEFT,
		v + Vector2.DOWN + Vector2.RIGHT,
		]

func gen_block(v):
	var block = get_borderv(v)
	for chunk in block:
		gen_chunk(chunk)
	for chunk in chunks.keys():
		if not chunk in block:
			kill_chunk(chunk)

func player_entered(coords):
	rpc_id(1, "update_player_coords", coords)
	gen_block(coords)
