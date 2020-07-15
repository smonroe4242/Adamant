extends Node2D
const level = preload("res://game/NoiseLevel.tscn")
const offset = Vector2(Global.chunk_offset, Global.chunk_offset)# second number is NoiseLevel.size
const size = Global.chunk_size
var simplex = OpenSimplexNoise.new()
var chunks = {}
var origin = Vector2(0, 0)

# initialize noise generator
func _enter_tree():
	make_noise()

# get the chunk the player starts in
func _ready():
	gen_chunk(origin)

# initialize OpenSimplexNoise parameters
func make_noise():
	simplex.seed = 13
	simplex.lacunarity = 2.0
	simplex.octaves = 1
	simplex.period = 10.0
	simplex.persistence = 1

func gen_chunk(v):
	if v in chunks.keys():
		return
	var lvl = level.instance()
	lvl.position = v * offset
	lvl.coords = v
	lvl.connect("player_entered", self, "player_entered")
	chunks[v] = lvl
	call_deferred("add_child", lvl)

func kill_chunk(v):
	if not v in chunks.keys():
		return
	print("Killing a chunk")
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

func gen_block(v):
	var block = get_borderv(v)
	for chunk in block:
		gen_chunk(chunk)
	for chunk in chunks.keys():
		if not chunk in block:
			kill_chunk(chunk)

func player_entered(coords):
	gen_block(coords)
