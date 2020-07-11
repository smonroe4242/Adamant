extends TileMap
# Instantiate
var noise = OpenSimplexNoise.new()
var grid = []
const size = 256
# Configure
func _ready():
	noise.seed = 13
	noise.lacunarity = 2.0
	noise.octaves = 2
	noise.period = 13.0
	noise.persistence = 1
	grid.resize(size + 1)
	for x in size:
		grid[x] = []
		grid[x].resize(size + 1)
		for y in size:
			grid[x][y] = -1 if noise.get_noise_2d(x, y) > 0 else 0
	for x in size:
		for y in size:
			set_cell(x, y, grid[x][y])
	#Another way to access noise values is to precompute a noise image:
	# This creates a 512x512 image filled with simplex noise (using the currently set parameters)
	#var noise_image = noise.get_image(512, 512)

	# You can now access the values at each position like in any other image
	#print(noise_image.get_pixel(10, 20))

	# Create grid
	pass # Replace with function body.
