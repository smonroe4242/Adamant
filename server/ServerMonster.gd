extends ServerActor
# left flip happens one block too soon on either end of path
# animation isn't always right, I seen one idling
# lines up on y better but needs an x alignment, like half a tile too far right
#var chunk
#var attack_timer
const STEP = 100
var path = []
var path_idx = 0
var path_len = 0
var path_dir = 1
var terrain : OpenSimplexNoise
const CUTOFF = Global.Cutoff
var ref
var path_offset = Vector2(Global.tile_size, Global.tile_size)
var point_offset = Vector2(-0.5, -1)
#func _ready():
#	attack_timer = Timer.new()
#	attack_timer.set_wait_time(2)
#	attack_timer.connect("timeout", self, "attack")
#	add_child(attack_timer)
#	attack_timer.start()

func _ready():
	._ready()
	make_path()

func make_path():
	animation = "run"
	ref = coords * Vector2(Global.chunk_size, Global.chunk_size)
	var base = ref + position
	while terrain.get_noise_2dv(base + Vector2(0, 1)) > CUTOFF:
		base.y += 1
	while terrain.get_noise_2dv(base + Vector2(0, 1)) <= CUTOFF:
		base.y += 1
	path.append((base + point_offset) * path_offset)
	set_position(path[0])
	var start = base
	while true:
		if terrain.get_noise_2dv(base + Vector2(1, 1)) <= CUTOFF and terrain.get_noise_2dv(base + Vector2(1, 2)) > CUTOFF:
			base += Vector2(1, 1)
		elif terrain.get_noise_2dv(base + Vector2(1, 0)) <= CUTOFF and terrain.get_noise_2dv(base + Vector2(1, 1)) > CUTOFF:
			base += Vector2(1, 0)
		elif terrain.get_noise_2dv(base + Vector2(1, -1)) <= CUTOFF and terrain.get_noise_2dv(base + Vector2(1, 0)) > CUTOFF:
			base += Vector2(1, -1)
		else:
			break
		path.push_back((base + point_offset) * path_offset)
	base = start
	while true:
		if terrain.get_noise_2dv(base + Vector2(-1, 1)) <= CUTOFF and terrain.get_noise_2dv(base + Vector2(-1, 2)) > CUTOFF:
			base += Vector2(-1, 1)
		elif terrain.get_noise_2dv(base + Vector2(-1, 0)) <= CUTOFF and terrain.get_noise_2dv(base + Vector2(-1, 1)) > CUTOFF:
			base += Vector2(-1, 0)
		elif terrain.get_noise_2dv(base + Vector2(-1, -1)) <= CUTOFF and terrain.get_noise_2dv(base + Vector2(-1, 0)) > CUTOFF:
			base += Vector2(-1, -1)
		else:
			break
		path_idx += 1
		path.push_front((base + point_offset) * path_offset)
	path = PoolVector2Array(path)	
	path_len = path.size() - 1

func attack():
	for loc in Global.get_area(coords):
		if actor_map.has(loc):
			for player in actor_map[loc]:
				rpc_id(player, "_attack")

func _physics_process(delta):
	var dist = get_position().distance_to(path[path_idx])
	if dist > 2:
		set_position(get_position().linear_interpolate(path[path_idx], (STEP * delta) / dist))
	else:
		path_idx += path_dir
		if path_idx > path_len or path_idx < 0:
			path_dir *= -1
			path_idx += path_dir
			left_flip = not left_flip

	position = Vector2(floor(position.x), floor(position.y))
	for loc in Global.get_area(coords):
		if actor_map.has(loc):
			for id in actor_map[loc].keys():
				set_puppet_vars(id)
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
	puppet_max_hp = max_hp
	puppet_hp = hp
	puppet_blocking = blocking

func die():
	var world = get_parent()
	print("Server: MOB DEATH ")
	for loc in Global.get_area(coords):
		if actor_map.has(loc):
			for player in actor_map[loc]:
				world.rpc_id(player, "unload_monster", name)
	print(monster_map)
	if monster_map.has(coords):
		if not monster_map[coords].erase(name):
			print("Server: ", name, " not found in monster_map[", coords, "] during death")
	else:
		print("Server: monster.die(): ", name, " with coords ", coords, " not even in the map???")
	queue_free()
