extends KinematicBody2D
class_name ServerActor
var actor_map
var monster_map
var level := 0
master var velocity := Vector2.UP
master var animation := "idle"
master var left_flip := false
master var hp := 59
master var max_hp := 59
master var coords
puppet var puppet_position# := Vector2()
puppet var puppet_velocity# := Vector2()
puppet var puppet_animation# := "idle"
puppet var puppet_left_flip# := false
puppet var puppet_hp
puppet var puppet_max_hp
puppet var puppet_coords

func _ready():
	coords = position / Global.offsetv
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
	puppet_max_hp = max_hp
	puppet_hp = hp
	puppet_coords = coords
### TODO master and pupper
remote func set_vars(p, v, a, l, m, h):
	position = p
	velocity = v
	animation = a
	left_flip = l
	max_hp = m
	hp = h

remote func request_damage(target):
	var parent = get_parent()
	# a naively trusting damage calculation
	var child = parent.get_node(str(target))
	if not child == null:
		print("damaging child: ", child.name)
		child.damage(30)
	else:
		print("Child ", target, " was not found")

func damage(amt):
	if (hp - amt <= 0):
		hp = 0
		die()
		rpc("damage", hp)
		rpc("die")
	else:
		hp -= amt
		rpc("damage", amt)

func die():
	# Implemented in subclasses
	pass
