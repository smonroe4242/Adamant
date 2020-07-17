extends Node2D
class_name NoiseLevel

var ladder = preload("res://game/Ladder.tscn")
var grid = []
enum biome {SKY, OVERWORLD, CAVE}
# Set by parent
var coords
var simplex
var size
var ref
var type
# Auto Tile Consts
const EMPTY = 0
const FILL = 1
const R_SLOPE = 2
const L_SLOPE = 3
const ROCK = 4
const L_BIG = 5
const R_BIG = 6
const LADDER = 7
## TODO make tiles bitmaskable
# autotile sets need to be adjusted for this, coop with nothawthorne
onready var noise = $Noise
onready var nav = $Nav

# apply procgen layers to create traversable map
func _ready():
	if type == biome.CAVE:
		gen_cave()
	elif type == biome.OVERWORLD:
		gen_overworld()
	elif type == biome.SKY:
		gen_skies()

### Start Sky Gen
func gen_skies():
	pass

### Start Overworld Gen
func gen_overworld():
	make_bottom()
	pass

func make_bottom():
	for y in size:
		for x in size:
			# add BG tiles of an overworld tileset
			if y > size - 2:
				# add grass and shit
				pass
			elif y > size / 3:
				# add mid level scenery
				pass
			else:
				# add sky
				pass

### Level Generation
func gen_cave():
	make_grid()
#	clear_paths() # leaving out until it works
	drop_ladders()
	smooth_noise()
	place_tiles()
# create binary from simplex noise floats
func make_grid():
	grid.resize(size)
	for x in size:
		grid[x] = []
		grid[x].resize(size)
		for y in size:
			grid[x][y] = EMPTY if simplex.get_noise_2dv(ref + Vector2(x, y)) < 0 else FILL

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
			if grid[x][y] == 1:
				bsq[x][y] = 1 + min(bsq[x][y - 1], min(bsq[x - 1][y], bsq[x - 1][y - 1]))
			else:
				bsq[x][y] = 0
			if maxsize < bsq[x][y]:
				maxsize = bsq[x][y]
				mx = x
				my = y
	for x in maxsize:
		for y in maxsize:
			grid[mx - x][my - y] = R_SLOPE
	var msz = 3
	for x in range(1, size):
		for y in range(1, size):
			if bsq[x][x] == msz and bsq[x - 1][y] == msz - 1 and bsq[x][y - 1] == msz - 1 and bsq[x-1][y-1] == msz - 1:
				for i in msz:
					for j in msz:
						grid[x - i][y - j] = L_SLOPE
# create Ladder objects at unjumpable overhangs
func drop_ladders():
	for x in range(1, size - 1):
		for y in range(1, size - 3):
			if grid[x][y] == EMPTY and grid[x][y + 1] == EMPTY and grid[x][y + 2] == EMPTY and (((grid[x - 1][y] != LADDER and grid[x - 1][y] != EMPTY) and grid[x - 1][y - 1] == EMPTY) or ((grid[x + 1][y] != LADDER and grid[x + 1][y] != EMPTY) and grid[x + 1][y - 1] == EMPTY)):
				var drop = y
				while drop < size and grid[x][drop] == EMPTY:
#					grid[x][drop] = LADDER
					drop += 1
				if drop == size and grid[x][size - 1] == EMPTY:
					while simplex.get_noise_2dv(ref + Vector2(x, drop)) < 0:
						drop += 1
#				drop -= 1
				var lad = ladder.instance()
				var collision = CollisionShape2D.new()
				collision.set_shape(RectangleShape2D.new())
				lad.add_child(collision)
				var half = (drop - y) / 2
				var sprite = lad.get_node("Sprite")
				sprite.set_region(true)
				sprite.set_region_rect(Rect2(Vector2(0, 0), Vector2(64, 64 * (drop - y))))
				lad.position = nav.map_to_world(Vector2(x, y + half))
				collision.get_shape().set_extents(Vector2(32, 64 * half))
				collision.position.x += 32
				call_deferred("add_child", lad)

# add slop blocks on one block high steps
func smooth_noise():
	for x in range(0, size - 1):
		for y in range(0, size - 1):
			if grid[x][y] == FILL and grid[x + 1][y] == EMPTY and grid[x+1][y + 1] == FILL:
				grid[x + 1][y] = R_SLOPE
			elif grid[x][y] == EMPTY and grid[x + 1][y] == FILL and grid[x][y + 1] == FILL:
				grid[x][y] = L_SLOPE

# transform from integer grid to tilemap
func place_tiles():
	for x in size:
		for y in size:
			var cell = grid[x][y]
			if cell == FILL: #colliding block
#				if x > 0 and grid[x-1][y] == FILL and randi() & 3 == 1:
#					noise.set_cell(x-1, y, L_BIG)
#					noise.set_cell(x, y, R_BIG)
#				else:
				noise.set_cell(x, y, ROCK)
			elif cell == L_SLOPE or cell == R_SLOPE:
				noise.set_cell(x, y, cell)
			else:
				noise.set_cell(x, y, (randi() & 7) + 10)
#			if cell == LADDER:
#				nav.set_cell(x, y, 0)

### End Level Genreation

signal player_entered
func _on_Area2D_area_entered(area):
	if not area.get_parent().get('onLadder') == null and area.is_network_master():
		emit_signal("player_entered", coords)
