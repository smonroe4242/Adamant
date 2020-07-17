extends KinematicBody2D

master var velocity := Vector2.UP
master var animation := "idle"
master var left_flip := false
master var hp := 100
var snap := Vector2(0, 16)
puppet var puppet_position := Vector2()
puppet var puppet_velocity := Vector2()
puppet var puppet_animation := "idle"
puppet var puppet_left_flip := false
puppet var puppet_hp = 100

func _ready():
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
	puppet_hp = hp
### TODO master and pupper
remote func set_vars(p, v, a, l, h):
	position = p
	velocity = v
	animation = a
	left_flip = l
	hp = h

remote func request_damage(targets):
	var parent = get_parent()
	# a naively trusting damage calculation
	for target in targets:
		var t = parent.get_node(str(target))
		if not t == null:
			t.damage(30)

func damage(amt):
	if (hp - amt <= 0):
		rpc("damage", hp)
	else:
		rpc("damage", amt)

func _physics_process(_delta):
	# server replica code
	rpc_unreliable("set_puppet_vars", position, velocity, animation, left_flip, hp)
	if not is_network_master():
		puppet_position = position
