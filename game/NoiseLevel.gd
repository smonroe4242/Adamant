extends Node2D
class_name NoiseLevel
var grid = []
var coords = Vector2()
var simplex
var size
# Auto Tile Consts
const EMPTY = 0
const FILL = 1
const R_SLOPE = 2
const L_SLOPE = 3
const ROCK = 4
const L_BIG = 5
const R_BIG = 6
const LADDER = 7

onready var noise = $Noise
onready var BG = $BG
onready var nav = $Nav

func _enter_tree():
	size = get_parent().size
	simplex = get_parent().simplex
# Helper Functions:
# is the cell cleared?
func clr(cell):
	return cell == EMPTY or cell == LADDER
# is the cell filled?
func fil(cell):
	return cell != EMPTY and cell != LADDER#not clr(cell)
# get the right tile
func _get_subtile_coord(id):
	var nil = Vector2(0, 0)
	if (id == 0):
		return nil
	var rect = noise.tile_set.tile_get_region(id)
	if rect.size == nil:
		return nil
	var x = (id % int(rect.size.x))
	var y = (id / int(rect.size.y))
	return Vector2(x, y)

### Level Generation

# create bitmap from simplex noise floats
func make_grid():
	var ref = coords * Vector2(size, size)
	grid.resize(size + 1)
	for x in size:
		grid[x] = []
		grid[x].resize(size+1)
		for y in size:
			grid[x][y] = EMPTY if simplex.get_noise_2dv(ref + Vector2(x, y)) < 0 else FILL

# TODO [fix bsq] find thin walls to make in to caves
func clear_paths():
	var bsq = []
	var maxsize = -1
	var mx = 0
	var my = 0
	bsq.resize(size + 1)
	for x in size:
		bsq[x] = []
		bsq[x].resize(size + 1)
		for y in size:
			bsq[x][y] = grid[x][y]
	for x in range(1, size):
		for y in range(1, size):
			if grid[x][y] == 1:
				bsq[x][y] = 1 + min(bsq[x][y - 1], min(bsq[x - 1][y], bsq[x - 1][y - 1]))
			if maxsize < bsq[x][y]:
				maxsize = bsq[x][y]
				mx = x
				my = y
			else:
				bsq[x][y] = 0
	for x in size:
		for y in size:
			if bsq[x][y] == maxsize - 1:
				for i in range(x, mx, -1):
					for j in range(y, my, -1):
						grid[i][j] = LADDER
# create Ladder objects at unjumpable overhangs
func drop_ladders():
	for x in range(1, size - 1):
		for y in range(1, size - 3):
			if clr(grid[x][y]) and clr(grid[x][y + 1]) and clr(grid[x][y + 2]) and ((fil(grid[x - 1][y]) and clr(grid[x - 1][y - 1])) or (fil(grid[x + 1][y]) and clr(grid[x + 1][y - 1]))):
				var drop = y
				while drop < size and clr(grid[x][drop]):
					grid[x][drop] = LADDER
					drop += 1
# add slop blocks on one block high steps
func smooth_noise():
	for x in range(0, size - 1):
		for y in range(0, size - 1):
			if fil(grid[x + 1][y + 1]) and grid[x][y - 1] != LADDER and clr(grid[x][y]) and clr(grid[x + 1][y]) and clr(grid[x][y + 1]):
					grid[x + 1][y + 1] = L_SLOPE
			elif fil(grid[x][y + 1]) and grid[x][y - 1] != LADDER and clr(grid[x][y]) and clr(grid[x + 1][y]) and clr(grid[x + 1][y + 1]):
					grid[x][y + 1] = R_SLOPE
# clear terrain between points a and b
func punch_cave(_a, _b):
	pass
# transform from integer grid to tilemap
func place_tiles():
	var ladder = preload("res://game/Ladder.tscn")
	for x in size:
		for y in size:
			var cell = grid[x][y]
			if cell > 0 and cell != L_SLOPE and cell != R_SLOPE: #colliding block
				if cell == LADDER:
					var lad = ladder.instance()
					lad.position = nav.map_to_world(Vector2(x, y))
					call_deferred("add_child", lad)
				elif x > 0 and randi() & 1 == 1 and fil(grid[x-1][y]):
					noise.set_cell(x-1, y, L_BIG)
					noise.set_cell(x, y, R_BIG)
				else:
					noise.set_cell(x, y, ROCK)
			else:
				noise.set_cell(x, y, cell, false, false, false, _get_subtile_coord(cell))
			BG.set_cell(x, y, (randi() & 7) + 10)

# apply procgen layers to create traversable map at coords
func _ready():
	make_grid()
#	clear_paths()
	drop_ladders()
	smooth_noise()
	place_tiles()

signal player_entered
func _on_Area2D_body_entered(body):
	if body.is_network_master() and not body.get('onLadder') == null:
		emit_signal("player_entered", coords)
