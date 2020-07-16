extends Node2D
class_name NoiseLevel

var ladder = preload("res://game/Ladder.tscn")
var grid = []
var coords = Vector2()
var simplex
var size
var ref
var type
enum biome {SKY, OVERWORLD, CAVE}
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
#onready var BG = $BG
onready var nav = $Nav

# initialize object
func _enter_tree():
# warning-ignore:unsafe_property_access
	$Area2D/CollisionShape2D.disabled = true
# warning-ignore:unsafe_property_access
	size = get_parent().size
	ref = coords * Vector2(size, size)
# warning-ignore:unsafe_property_access
	simplex = get_parent().simplex
# then
# apply procgen layers to create traversable map
func _ready():
	print("Chunk ready of type ", type)
	if type == biome.CAVE:
		gen_cave()
	elif type == biome.OVERWORLD:
		gen_overworld()
	elif type == biome.SKY:
		gen_skies()
# warning-ignore:unsafe_property_access
	$Area2D/CollisionShape2D.disabled = false
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
			noise.set_cell(x, y, 10)


### Level Generation
func gen_cave():
	make_grid()
	drop_ladders()
	smooth_noise()
	place_tiles()
# create bitmap from simplex noise floats
func make_grid():
	grid.resize(size + 1)
	for x in size:
		grid[x] = []
		grid[x].resize(size+1)
		for y in size:
			grid[x][y] = EMPTY if simplex.get_noise_2dv(ref + Vector2(x, y)) < 0 else FILL

# TODO [fix bsq] find thin walls to make in to caves
#func clear_paths():
#	var bsq = []
#	var maxsize = -1
#	var mx = 0
#	var my = 0
#	bsq.resize(size + 1)
#	for x in size:
#		bsq[x] = []
#		bsq[x].resize(size + 1)
#		for y in size:
#			bsq[x][y] = grid[x][y]
#	for x in range(1, size):
#		for y in range(1, size):
#			if grid[x][y] == 1:
#				bsq[x][y] = 1 + min(bsq[x][y - 1], min(bsq[x - 1][y], bsq[x - 1][y - 1]))
#			if maxsize < bsq[x][y]:
#				maxsize = bsq[x][y]
#				mx = x
#				my = y
#			else:
#				bsq[x][y] = 0
#	for x in size:
#		for y in size:
#			if bsq[x][y] == maxsize - 1:
#				for i in range(x, mx, -1):
#					for j in range(y, my, -1):
#						grid[i][j] = LADDER
# create Ladder objects at unjumpable overhangs
func drop_ladders():
	for x in range(1, size - 1):
		for y in range(1, size - 3):
			if grid[x][y] == EMPTY and grid[x][y + 1] == EMPTY and grid[x][y + 2] == EMPTY and (((grid[x - 1][y] != LADDER and grid[x - 1][y] != EMPTY) and grid[x - 1][y - 1] == EMPTY) or ((grid[x + 1][y] != LADDER and grid[x + 1][y] != EMPTY) and grid[x + 1][y - 1] == EMPTY)):
					var drop = y
					while drop < size and grid[x][drop] == EMPTY:
						var lad = ladder.instance()
						lad.position = nav.map_to_world(Vector2(x, drop))
						call_deferred("add_child", lad)
						drop += 1
					if drop == size:
						while simplex.get_noise_2dv(ref + Vector2(x, drop)) < 0:
							var lad = ladder.instance()
							lad.position = nav.map_to_world(Vector2(x, drop))
							call_deferred("add_child", lad)
							drop += 1

# add slop blocks on one block high steps
func smooth_noise():
	for x in range(0, size - 1):
		for y in range(0, size - 1):
			if grid[x][y] > EMPTY and grid[x + 1][y] == EMPTY and grid[x+1][y + 1] > EMPTY:
				grid[x + 1][y] = R_SLOPE
			elif grid[x][y] == EMPTY and grid[x + 1][y] > EMPTY and grid[x][y + 1] > EMPTY:
				grid[x][y] = L_SLOPE
#			if grid[x][y] == FILL and grid[x + 1][y] == EMPTY and grid[x+1][y + 1] == FILL:
#				grid[x + 1][y] = R_SLOPE
#			elif grid[x][y] == EMPTY and grid[x + 1][y] == FILL and grid[x][y + 1] == FILL:
#				grid[x][y] = L_SLOPE
# transform from integer grid to tilemap
func place_tiles():
	for x in size:
		for y in size:
			var cell = grid[x][y]
			if cell == FILL: #colliding block
				if x > 0 and grid[x-1][y] == FILL and randi() & 3 == 1:
					noise.set_cell(x-1, y, L_BIG)
					noise.set_cell(x, y, R_BIG)
				else:
					noise.set_cell(x, y, ROCK)
			else:
#				noise.set_cell(x, y, cell)
				noise.set_cell(x, y, (randi() & 7) + 10)

### End Level Genreation

signal player_entered
func _on_Area2D_area_entered(area):
	if not area.get_parent().get('onLadder') == null and area.is_network_master():
		print("Player entry ", coords)
		emit_signal("player_entered", coords)
