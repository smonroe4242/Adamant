extends ServerActor

var simplex
var chunk
var attack_timer

func _ready():
	return
	attack_timer = Timer.new()
	attack_timer.set_wait_time(2)
	attack_timer.connect("timeout", self, "attack")
	add_child(attack_timer)
	attack_timer.start()

func attack():
	return
	for chunk in Global.get_area(coords):
		if actor_map.has(chunk):
			for player in actor_map[chunk]:
				rpc_id(player, "_attack")

func _physics_process(_delta):
	return
	coords = Vector2(int(floor(position.x / Global.offsetv.x)), int(floor(position.y / Global.offsetv.y)))
	for chunk in Global.get_area(coords):
		if actor_map.has(chunk):
			for player in actor_map[chunk]:
				rpc_unreliable_id(player, "set_vars", position, velocity, animation, left_flip, max_hp, hp, coords)

func die():
	return
	var world = get_parent()
	print("Server: MOB DEATH ")
	for chunk in Global.get_area(coords):
		if actor_map.has(chunk):
			for player in actor_map[chunk]:
				world.rpc_id(player, "unload_monster", name)
	if not monster_map[coords].erase(name):
		print("Server: ", name, " not found in monster_map[", coords, "] during death")
	queue_free()
