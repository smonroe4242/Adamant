extends TileMap
var grid = [] # map[SZ][SZ]
const SZ = 32 # size of map
const HGT = 4 # tunnel height plus one
const X = 0 # filled tile
const O = -1 # empty tile

# Do we need a tile to access the tunnel above?
func is_space(grid, x, y):
	
	if y < 1 or grid[x][y - 1] == X:
		return false
	if x < SZ - 2 and grid[x - 1][y - 1] == X and grid[x + 1][y - 1] == O and grid[x + 2][y - 1] == O:
		return true
	return false

# Called on load
func _ready():
	# New random each time, switch to set_seed when not testing
	randomize()
	
	# malloc space
	grid.resize(SZ + 1)
	for x in SZ:
		grid[x] = []
		grid[x].resize(SZ + 1)

	# Make map borders and equidistant platforms with holes
	for x in SZ:
		for y in SZ:
			# Borders
			if x == 0 or y == 0 or x == SZ -1 or y == SZ - 1:
				grid[x][y] = X
			# Platforms
			elif y % HGT == 0:
				# With holes
				grid[x][y] = O if randi() % 5 == 0 else X
			# Fill the rest with empty space
			else:
				grid[x][y] = O

	for y in range(0, SZ - 1, HGT):
		print("Spacew checl", y)
		for x in range(3, SZ - 3):
			if grid[x - 2][y] == X and grid[x - 1][y] == O and grid[x][y] == X and grid[x + 1][y] == O and grid[x + 2][y] == X:
				grid[x][y] = O

	# Second pass to add stairs
	for h in range(1, HGT):
		for x in range(1, SZ - 1):
			for y in range(1, SZ - 1):
				if y % HGT == h:
					grid[x][y] = X if is_space(grid, x, y) else O

	# Create tilemap based on populated grid
	for x in SZ:
		for y in SZ:
			set_cell(x, y, grid[x][y])
