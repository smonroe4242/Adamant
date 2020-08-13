extends ServerActor
var xp = 0
var puppet_xp : int
var puppet_level : int

func _physics_process(_delta):
	var new_coords = Vector2(floor(position.x / Global.offsetv.x), floor(position.y / Global.offsetv.y))
	if new_coords != coords:
		coords = new_coords

	for chunk in Global.get_area(coords):
		if actor_map.has(chunk):
			for id in actor_map[chunk].keys():
				if int(id) != int(name):
					set_puppet_vars(id)
				set_other_vars(id)
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
	puppet_max_hp = max_hp
	puppet_hp = hp
	puppet_blocking = blocking
	puppet_level = level
	puppet_xp = xp

func set_other_vars(id):
	if puppet_level != level:
		print("LEVEL CHANGING ", puppet_level, " >> ", level)
		rset_id(id, 'puppet_level', level)
	if puppet_xp != xp:
		print("XP CHANGING ", puppet_xp, " >> ", xp)
		rset_id(id, 'puppet_xp', xp)

func earn_xp(amt):
	xp += amt
	var lvl = int(log((xp + 1000) / 1000.0) * 11) + 1
	if level != lvl:
		level = lvl
	print("Server: Xp Earned: ", name, ": xp: ", xp, ", level: ", level)

func die():
	print("Server: Player DEATH")
	hp = 0
	animation = "death"
