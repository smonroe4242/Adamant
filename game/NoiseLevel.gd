extends Node2D
class_name NoiseLevel

var ladder : PackedScene = preload("res://game/Ladder.tscn")
var grid : Array = []
enum biome {Underworld, Ground, Overworld}
const size : int = Global.chunk_size + 2
const pix : int = Global.tile_size
const hpix : int = Global.tile_size >> 1
var deep_v : float = 1.0
var deep_x : int = 0
var deep_y : int = 0
# Set by parent
var coords : Vector2
var terrain_noise : OpenSimplexNoise
var biome_noise : OpenSimplexNoise
var ref : Vector2
var type : int
# Auto Tile Consts
const EMPTY = -1
const FILL = 0
const LADDER = 7
const CUTOFF = Global.Cutoff
onready var noise = $Noise
# apply procgen layers to create traversable map
func _ready() -> void:
	noise.modulate = get_biome_color()
	match type:
		biome.Underworld:
			gen_underworld()
		biome.Ground:
			gen_groundlevel()
		biome.Overworld:
			gen_overworld()

func get_biome_color() -> Color:
	var hint = biome_noise.get_noise_2dv(coords)
	if hint > 0.5:
		return Color(1, 0, 0, 1) # Red
	if hint > 0:
		return Color(1, 1, 0, 1) # Yellow
	if hint > -0.5:
		return Color(0, 1, 0, 1) # Green
	return Color(0, 0, 1, 1) # Blue

### Start Sky Gen
func gen_overworld() -> void:
	# For if people can go up from ground level, -y chunk vals
	pass

### Start Overworld Gen
func gen_groundlevel() -> void:
	# The top layer with buildings and some npcs, spawn layer
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
		ground[x] = FILL if terrain_noise.get_noise_2dv(ref + Vector2(x, size - 2)) > CUTOFF else EMPTY
		overlap[x] = FILL if terrain_noise.get_noise_2dv(ref + Vector2(x, size - 1)) > CUTOFF else EMPTY
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
func make_grid(height: int) -> void:
	grid.resize(size)
	for x in size:
		grid[x] = []
		grid[x].resize(height)
		for y in size:
			var point = terrain_noise.get_noise_2dv(ref + Vector2(x, y))
			if point < deep_v:
				deep_x = x
				deep_y = y
				deep_v = point
			grid[x][y] = FILL if point > CUTOFF else EMPTY

# create Ladder objects at unjumpable overhangs
func drop_ladders(height: int) -> void:
	for x in range(1, size - 1):
		for y in range(1, height - 1):
			if grid[x][y] == EMPTY and grid[x][y + 1] == EMPTY and ( ( grid[x - 1][y] != EMPTY and grid[x - 1][y - 1] == EMPTY) or (grid[x + 1][y] != EMPTY and grid[x + 1][y - 1] == EMPTY)):
				var drop = y
				while drop < size and grid[x][drop] == EMPTY:
					drop += 1
				make_ladder(x, y, drop)

func make_ladder(x: int, y: int, drop: int) -> void:
	while terrain_noise.get_noise_2dv(ref + Vector2(x, drop)) <= CUTOFF:
		drop += 1
	var height = drop - y
	if height < 3:
		return
	var fix = Vector2(0, 0 if height & 1 == 1 else -hpix)
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
func place_tiles(height: int) -> void:
	for x in size:
		for y in height:
			if grid[x][y] == FILL:
				noise.set_cell(x, y, 1)

	### TMP MOB STUFF
#	var mob = preload("res://game/Monster.tscn").instance()
#	mob.displayName = "BigBoi LVL" + str(coords.y)
#	mob.level = coords.y
#	mob.coords = coords
#	mob.position = Vector2(deep_x, deep_y)
#	mob.ref = ref
#	mob.name = "M" + str(mob.get_instance_id())
#	mob.max_hp = coords.y * 100
#	mob.hp = mob.max_hp
#	mob.terrain = terrain_noise
#	mob.CUTOFF = CUTOFF
#	my_mob = mob
#	add_child(mob)
	# Run autotiler
	noise.update_bitmask_region()
	# Erase overlapped borders
	for x in size:
		noise.set_cell(0,    x, -1)
		noise.set_cell(size - 1, x, -1)
		noise.set_cell(x,    0, -1)
		noise.set_cell(x, size - 1, -1)
### End Level Generation

