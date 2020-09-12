extends ServerActor

func _physics_process(_delta):
	var new_coords = Vector2(int(floor(position.x / Global.offsetv.x)), int(floor(position.y / Global.offsetv.y)))
	if new_coords != coords:
		coords = new_coords

	for chunk in Global.get_area(coords):
		if actor_map.has(chunk):
			for id in actor_map[chunk].keys():
				if int(id) != int(name):
					set_puppet_vars(id, position, animation, left_flip, max_hp, hp, blocking, state, strength, stamina, intellect, wisdom, dexterity, luck)
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
	puppet_max_hp = max_hp
	puppet_hp = hp
	puppet_blocking = blocking

func die():
	print("Server: Player DEATH")
	hp = 0
	animation = "death"
