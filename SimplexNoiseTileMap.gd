extends TileMap
# Instantiate
var noise = OpenSimplexNoise.new()
var grid = []
const size = 128
# Configure
func _get_subtile_coord(id):
	print(id)
	if (id == 0):
		return Vector2(0, 0)
	var rect = tile_set.tile_get_region(id)
	var x = (id % int(rect.size.x))
	var y = (id / int(rect.size.y))
	return Vector2(x, y)

func _ready():
	noise.seed = 13
	noise.lacunarity = 2.0
	noise.octaves = 1
	noise.period = 5.0
	noise.persistence = 1
	grid.resize(size + 1)
	for x in size:
		grid[x] = []
		grid[x].resize(size + 1)
		for y in size:
			grid[x][y] = 0 if noise.get_noise_2d(x, y) > 0 else 1
	for x in size:
		for y in size:
			set_cell(x, y, grid[x][y], false, false, false, _get_subtile_coord(grid[x][y]))
	#Another way to access noise values is to precompute a noise image:
	# This creates a 512x512 image filled with simplex noise (using the currently set parameters)
	#var noise_image = noise.get_image(512, 512)

	# You can now access the values at each position like in any other image
	#print(noise_image.get_pixel(10, 20))

	# Create grid
	pass # Replace with function body.
