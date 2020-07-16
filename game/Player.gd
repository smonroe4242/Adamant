extends KinematicBody2D

#const UP = Vector2(0, -1)
const GRAV = 20
const STEP = 450
const JUMP = 500
master var velocity := Vector2.UP
master var animation := "idle"
master var left_flip := false
var jumping := false
var snap := Vector2(0, 16)
var onLadder := int(0)
var displayName := "New Player"
puppet var puppet_position := Vector2()
puppet var puppet_velocity := Vector2()
puppet var puppet_animation := "idle"
puppet var puppet_left_flip := false
onready var sprite := $AnimatedSprite
onready var label := $Label

func _ready():
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
# warning-ignore:unsafe_property_access
	label.text = displayName

# unsafe because network ownership is not checked
# but we had an error with it so come back when we understand
# godot networking better
### TODO master and pupper
remote func set_vars(p, v, a, l):
	position = p
	velocity = v
	animation = a
	left_flip = l

remote func set_puppet_vars(p, v, a, l):
	puppet_position = p
	puppet_velocity = v
	puppet_animation = a
	puppet_left_flip = l

func _physics_process(_delta):
	if is_network_master():
		# client og code
		velocity.y += GRAV
		if Input.is_action_pressed('ui_right'):
			velocity.x = STEP
			if is_on_floor():
				animation = "run"
			left_flip = false
		elif Input.is_action_pressed('ui_left'):
			velocity.x = -STEP
			if is_on_floor():
				animation = "run"
			left_flip = true
		else:
			velocity.x = 0
			if is_on_floor():
				animation = "idle"

		if onLadder == 0:
			if is_on_floor():
				if Input.is_action_pressed('ui_up'):
					velocity.y = -STEP
					animation = "jump_start"
					jumping = true
					snap = Vector2(0, 0)
				elif jumping == true:
					animation = "jump_end"
					jumping = false
					snap = Vector2(0, 16)
		else:
			animation = "idle"
			velocity.y = 0
			if Input.is_action_pressed('ui_up'):
				velocity.y = -STEP
			elif Input.is_action_pressed('ui_down'):
				velocity.y = STEP
# server replica, client replica, client og
# client og moves, sends vars to server replica, so master
# server replica (verifies and) sends vars to client replicas, so master? but puppet for owning client?
# client replicas only receive, so puppet
		rpc_unreliable_id(1, "set_vars", position, velocity, animation, left_flip)
	else:
		#client replica code
		set_vars(
			puppet_position,
			puppet_velocity,
			puppet_animation,
			puppet_left_flip)

# warning-ignore:unsafe_method_access
	sprite.set_flip_h(left_flip)
# warning-ignore:unsafe_property_access
	sprite.animation = animation

	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 4, rad2deg(90))
	if not is_network_master():
		puppet_position = position

func set_display_name(user):
		displayName = user
