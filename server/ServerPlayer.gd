extends KinematicBody2D

master var velocity := Vector2.UP
master var animation := "idle"
master var left_flip := false
var snap := Vector2(0, 16)
puppet var puppet_position := Vector2()
puppet var puppet_velocity := Vector2()
puppet var puppet_animation := "idle"
puppet var puppet_left_flip := false

func _ready():
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
### TODO master and pupper
remote func set_vars(p, v, a, l):
	position = p
	velocity = v
	animation = a
	left_flip = l

func _physics_process(_delta):
	# server replica code
	rpc_unreliable("set_puppet_vars", position, velocity, animation, left_flip)
	if not is_network_master():
		puppet_position = position
