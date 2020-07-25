extends ServerActor

func _physics_process(_delta):
	var new_coords = Vector2(int(floor(position.x / Global.offsetv.x)), int(floor(position.y / Global.offsetv.y)))
	if new_coords != coords:
		coords = new_coords
	puppet_position = position
	for chunk in Global.get_area(coords):
		if actor_map.has(chunk):
			for id in actor_map[chunk].keys():
				rpc_unreliable_id(id, "set_puppet_vars", position, velocity, animation, left_flip, max_hp, hp)

func die():
	print("Server: Player DEATH")
	hp = 0
	animation = "death"
