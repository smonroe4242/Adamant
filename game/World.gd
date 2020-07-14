extends Node2D

const LVL = preload("res://game/NoiseLevel.tscn")
const OFF = Global.chunk_offset# second number is NoiseLevel.size
var chunks = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	print("World ready")
	var origin = Vector2(0, 0)
	gen_chunk(origin)

func gen_chunk(v):
	if v in chunks.keys():
		return
	var lvl = LVL.instance()
#	var ext = OFF / 2
#	var box = BoxShape.new()
#	box.set_extents(Vector3(ext, ext, 0))
#	var col = lvl.get_node("Area2D/CollisionShape2D")
#	col.shape = box
#	col.position = Vector2(ext, ext)
	lvl.position = v * Vector2(OFF,OFF)
	lvl.coords = v
	lvl.connect("player_entered", self, "player_entered")
	chunks[v] = lvl
	call_deferred("add_child", lvl)

func make_chunks(list):
	for chunk in list:
		gen_chunk(chunk)

func kill_chunk(v):
	if not v in chunks.keys():
		return
	remove_child(chunks[v])
	chunks[v].queue_free()
	chunks.erase(v)

func free_chunks(list):
	for chunk in list:
		kill_chunk(chunk)

func get_borderv(origin):
	return [
		origin, 
		origin + Vector2.UP,
		origin + Vector2.DOWN,
		origin + Vector2.LEFT,
		origin + Vector2.RIGHT,
		origin + Vector2.UP + Vector2.LEFT,
		origin + Vector2.UP + Vector2.RIGHT,
		origin + Vector2.DOWN + Vector2.LEFT,
		origin + Vector2.DOWN + Vector2.RIGHT,
		]

func gen_block(v):
	var block = get_borderv(v)
	make_chunks(block)
#	free_chunks(chunks.keys())
	for chunk in chunks.keys():
		if not chunk in block:
			kill_chunk(chunk)

func player_entered(coords):
	gen_block(coords)
