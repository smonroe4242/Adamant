extends Node2D
class_name NoiseLevel

var ladder = preload("res://game/Ladder.tscn")
var grid = []
enum biome {SKY, OVERWORLD, CAVE}
const size = Global.chunk_size
# Set by parent
var coords
var simplex
var ref
var type
# Auto Tile Consts
const EMPTY = -1
const FILL = 0
const LADDER = 7
onready var noise = $Noise

# apply procgen layers to create traversable map
func _ready():
	match type:
		biome.CAVE:
			gen_cave()
		biome.OVERWORLD:
			gen_overworld()
		biome.SKY:
			gen_skies()

### Start Sky Gen
func gen_skies():
	pass

### Start Overworld Gen
func gen_overworld():
	make_buildings()
	make_bottom()
	pass

# Create buildings on the overworld
func make_buildings():
	pass

# drop ladders to the underworld
func make_bottom():
	var ground = []
	ground.resize(size + 1)
	for x in size + 1:
		ground[x] = floor(simplex.get_noise_2dv(ref + Vector2(x, size)))
	for x in size:
		if ground[x] == EMPTY and ground[x + 1] == FILL:
			make_ladder(x, size, size)
			ground[x] = LADDER
		elif ground[x] == FILL and ground[x + 1] == EMPTY:
			make_ladder(x + 1, size, size)
			ground[x + 1] = LADDER

### Level Generation
func gen_cave():
	make_grid()
#	clear_paths()
	drop_ladders()
	place_tiles()

# create binary from simplex noise floats
func make_grid():
	grid.resize(size)
	for x in size:
		grid[x] = []
		grid[x].resize(size)
		for y in size:
			grid[x][y] = floor(simplex.get_noise_2dv(ref + Vector2(x, y)))

# TODO see if there's an efficient way to use bsq to find thin walls
func clear_paths():
	var bsq = []
	var maxsize = -1
	var mx = 0
	var my = 0
	bsq.resize(size)
	for x in size:
		bsq[x] = []
		bsq[x].resize(size)
	for x in size:
		bsq[x][0] = grid[x][0]
	for y in size:
		bsq[0][y] = grid[0][y]
	for x in range(1, size):
		for y in range(1, size):
			if grid[x][y] == FILL:
				bsq[x][y] = 1 + min(bsq[x][y - 1], min(bsq[x - 1][y], bsq[x - 1][y - 1]))
			else:
				bsq[x][y] = 0
			if maxsize < bsq[x][y]:
				maxsize = bsq[x][y]
				mx = x
				my = y
	var max_sz = 5
	for x in range(1, size - 1):
		for y in range(1, size - 1):
			if bsq[x][y] < max_sz and bsq[x][y] > 0:
				var msz = bsq[x][y]
				if bsq[x][y] == msz and bsq[x+1][y+1] == 0 and bsq[x - msz][y - msz] == 0:
					for i in msz:
						for j in msz:
							grid[x - i][y - j] = EMPTY

# create Ladder objects at unjumpable overhangs
func drop_ladders():
	for x in range(1, size - 1):
		for y in range(1, size - 3):
			if grid[x][y] == EMPTY and grid[x][y + 1] == EMPTY and grid[x][y + 2] == EMPTY and ( ( grid[x - 1][y] != EMPTY and grid[x - 1][y - 1] == EMPTY) or (grid[x + 1][y] != EMPTY and grid[x + 1][y - 1] == EMPTY)):
				var drop = y
				while drop < size and grid[x][drop] == EMPTY:
					drop += 1
				make_ladder(x, y, drop)

func make_ladder(x, y, drop):
	while floor(simplex.get_noise_2dv(ref + Vector2(x, drop))) == EMPTY:
		drop += 1
	if drop <= y:
		return
	var lad = ladder.instance()
	var collision = CollisionShape2D.new()
	collision.set_shape(RectangleShape2D.new())
	lad.add_child(collision)
	var half = (drop - y) / 2
	var sprite = lad.get_node("Sprite")
	sprite.set_region(true)
	sprite.set_region_rect(Rect2(Vector2(0, 0), Vector2(16, 16 * (drop - y))))
	sprite.set_z_index(0)
	lad.position = noise.map_to_world(Vector2(x, y + half))
	collision.get_shape().set_extents(Vector2(8, 16 * half))
	collision.position += Vector2(8, 16)
	call_deferred("add_child", lad)

# transform from integer grid to tilemap
func place_tiles():
	for x in size:
		for y in size:
			if grid[x][y] == FILL: #colliding block
				noise.set_cell(x, y, 1)
	noise.update_bitmask_region()
### End Level Generation
