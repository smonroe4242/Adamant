extends Node2D

export var grid = []
const size = 128
var simplex = OpenSimplexNoise.new()
# Auto Tile Consts
const L_SLOPE = 2
const R_SLOPE = 3
const LADDER = 4

onready var noise = $Noise
onready var nav = $Nav
# Helper Functions:
# is the cell cleared?
func clr(cell):
	return cell == 0 or cell == LADDER

# is the cell filled?
func fil(cell):
	return not clr(cell)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func make_noise():
	simplex.seed = 13
	simplex.lacunarity = 1.5
	simplex.octaves = 1
	simplex.period = 10.0
	simplex.persistence = 1

func make_grid():
	grid.resize(size + 1)
	for x in size:
		grid[x] = []
		grid[x].resize(size+1)
		for y in size:
			grid[x][y] = 0 if simplex.get_noise_2d(x, y) < 0 else 1

func drop_ladders():
	for x in range(1, size - 1):
		for y in range(1, size - 3):
			if clr(grid[x][y]) and ((fil(grid[x - 1][y]) and clr(grid[x - 1][y - 1])) or (fil(grid[x + 1][y]) and clr(grid[x + 1][y - 1]))):
				if clr(grid[x][y + 1]) and clr(grid[x][y + 2]):
					var drop = y
					while drop < size and clr(grid[x][drop]):
						grid[x][drop] = LADDER
						drop += 1
#					get_parent().call_deferred("add_child", Ladder.new(drop - y))

func smooth_noise():
	for x in range(0, size - 1):
		for y in range(0, size - 1):
			if clr(grid[x][y]) and clr(grid[x + 1][y]) and clr(grid[x][y + 1]) and fil(grid[x + 1][y + 1]):
				grid[x + 1][y + 1] = L_SLOPE
			elif clr(grid[x][y]) and clr(grid[x + 1][y]) and fil(grid[x][y + 1]) and clr(grid[x + 1][y + 1]):
				grid[x][y + 1] = R_SLOPE

func clear_paths():
	pass
	for _x in range(1, size - 1):
		for _y in range(1, size - 1):
			pass

func place_tiles():
	for x in size:
		for y in size:
			if grid[x][y] == LADDER:
				nav.set_cell(x, y, 0)
			else:
				noise.set_cell(x, y, grid[x][y], false, false, false, _get_subtile_coord(grid[x][y]))

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
# Called when the node enters the scene tree for the first time.
func _ready():
	make_noise()
	make_grid()
	drop_ladders()
	smooth_noise()
	place_tiles()

