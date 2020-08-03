extends Node2D
class_name NoiseLevel

var ladder = preload("res://game/Ladder.tscn")
var grid = []
enum biome {Underworld, Ground, Overworld}
const size = Global.chunk_size + 2
const pix = Global.tile_size
const hpix = Global.tile_size >> 1
# Set by parent
var coords
var terrain_noise
var biome_noise
var ref
var type
# Auto Tile Consts
const EMPTY = -1
const FILL = 0
const LADDER = 7
onready var noise = $Noise

# apply procgen layers to create traversable map
func _ready() -> void:
#	if int(coords.y) & 1:
	noise.modulate = get_biome_color()
	match type:
		biome.Underworld:
			gen_underworld()
		biome.Ground:
			gen_groundlevel()
		biome.Overworld:
			gen_overworld()

func get_biome_color() -> Color:
	# var colors = [
	# 	Color(1, 0, 0, 1),
	# 	Color(1, 1, 0, 1),
	# 	Color(0, 1, 0, 1),
	# 	Color(0, 1, 1, 1),
	# 	Color(0, 0, 1, 1),
		# Color(1, 0, 1, 1),
		# ]
	var hint = biome_noise.get_noise_2dv(coords)
	if hint > 0.5:
		return Color(1, 0, 0, 1)
	if hint > 0:
		return Color(1, 1, 0, 1)
	if hint > -0.5:
		return Color(0, 1, 0, 1)
	return Color(0, 0, 1, 1)
#	return colors[int(coords.x) % colors.size()]

### Start Sky Gen
func gen_overworld() -> void:
	pass

### Start Overworld Gen
func gen_groundlevel() -> void:
	make_buildings()
	make_bottom()
	pass

# Create buildings on the overworld
func make_buildings() -> void:
	pass

# drop ladders to the underworld
func make_bottom() -> void:
	var ground = []
	var overlap = []
	ground.resize(size + 1)
	overlap.resize(size + 1)
	for x in size + 1:
		ground[x] = floor(terrain_noise.get_noise_2dv(ref + Vector2(x, size - 2)))
		overlap[x] = floor(terrain_noise.get_noise_2dv(ref + Vector2(x, size - 1)))
	for x in size:
		if ground[x] == EMPTY and ground[x + 1] == FILL:
			make_ladder(x, size - 2, size - 2)
			ground[x] = LADDER
		elif ground[x] == FILL and ground[x + 1] == EMPTY:
			make_ladder(x + 1, size - 2, size - 2)
			ground[x + 1] = LADDER
		if ground[x] == FILL:
			noise.set_cell(x, size - 2, 1)
		if overlap[x] == FILL:
			noise.set_cell(x, size - 1, 1)
	noise.update_bitmask_region()
	for x in size:
		noise.set_cell(x, size - 1, -1)
	noise.set_cell(size - 1, size - 2, -1)
	noise.set_cell(0, size - 2, -1)

### Level Generation
func gen_underworld() -> void:
	make_grid(size)
#	clear_paths()
	drop_ladders(size)
	place_tiles(size)

# create binary matrix from terrain_noise noise floats
func make_grid(height) -> void:
	grid.resize(size)
	for x in size:
		grid[x] = []
		grid[x].resize(height)
		for y in size:
			grid[x][y] = floor(terrain_noise.get_noise_2dv(ref + Vector2(x, y)))

# TODO see if there's an efficient way to use bsq to find thin walls
func clear_paths() -> void:
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
func drop_ladders(height) -> void:
	for x in range(1, size - 1):
		for y in range(1, height - 1):
			if grid[x][y] == EMPTY and grid[x][y + 1] == EMPTY and ( ( grid[x - 1][y] != EMPTY and grid[x - 1][y - 1] == EMPTY) or (grid[x + 1][y] != EMPTY and grid[x + 1][y - 1] == EMPTY)):
				var drop = y
				while drop < size and grid[x][drop] == EMPTY:
					drop += 1
				make_ladder(x, y, drop)

func make_ladder(x, y, drop) -> void:
	while floor(terrain_noise.get_noise_2dv(ref + Vector2(x, drop))) == EMPTY:
		drop += 1
	var height = drop - y
	if height < 3:
		return
	var fix = Vector2(0, 0 if height & 1 == 1 else -pix / 2)
	var lad = ladder.instance()
	var collision = CollisionShape2D.new()
	var sprite = lad.get_node("Sprite")
	lad.add_child(collision)
	lad.position = noise.map_to_world(Vector2(x, y + (height / 2))) + fix
	sprite.set_region(true)
	sprite.set_region_rect(Rect2(Vector2(0, 0), Vector2(pix, pix * height)))
	sprite.set_z_index(0)
	collision.set_shape(RectangleShape2D.new())
	collision.get_shape().set_extents(Vector2(hpix, hpix * height))
	collision.position += Vector2(hpix, hpix)
	call_deferred("add_child", lad)

# transform from integer grid to tilemap
func place_tiles(height) -> void:
	# Set tiles
	for x in size:
		for y in height:
			if grid[x][y] == FILL: #colliding block
				noise.set_cell(x, y, 1)
	# Run autotiler
	noise.update_bitmask_region()
	# Erase overlapped borders
	for x in size:
		noise.set_cell(0,    x, -1)
		noise.set_cell(size - 1, x, -1)
		noise.set_cell(x,    0, -1)
		noise.set_cell(x, size - 1, -1)
### End Level Generation
