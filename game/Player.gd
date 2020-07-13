extends KinematicBody2D

const UP = Vector2(0, -1)
const GRAV = 20
const STEP = 450
const JUMP = 500
var velocity = Vector2.UP
var animation = "idle"
var left_flip = false
var jumping = false
var snap = Vector2(0, 16)
var onLadder := int(0)
puppet var puppet_pos := Vector2()
puppet var puppet_vel := Vector2()
puppet var puppet_ani
puppet var puppet_lft

func _ready():
	puppet_pos = position
	puppet_ani = animation
	puppet_lft = left_flip

func _physics_process(delta):
	
	if is_network_master():
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
				if Input.is_action_just_pressed('ui_up'):
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
			
		rset_unreliable("puppet_pos", position)
		rset_unreliable("puppet_vel", velocity)
		rset_unreliable("puppet_ani", animation)
		rset_unreliable("puppet_lft", left_flip)
	else:
		position = puppet_pos
		velocity = puppet_vel
		animation = puppet_ani
		left_flip = puppet_lft

	$AnimatedSprite.set_flip_h(left_flip)
	$AnimatedSprite.animation = animation

	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 4, rad2deg(90))
	if not is_network_master():
		puppet_pos = position
