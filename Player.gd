extends KinematicBody2D

const UP = Vector2(0, -1)
const GRAV = 20
const STEP = 800
const JUMP = -20
var velocity = Vector2.UP
var state = "falling"
var left_flip = false
var jumping = false

func _physics_process(delta):
	velocity.y += GRAV
	if Input.is_action_pressed('ui_right'):
		velocity.x = STEP
		if is_on_floor():
			$AnimatedSprite.animation = "run"
		left_flip = false
	elif Input.is_action_pressed('ui_left'):
		velocity.x = -STEP
		if is_on_floor():
			$AnimatedSprite.animation = "run"
		left_flip = true
	else:
		velocity.x = 0
		if is_on_floor():
			$AnimatedSprite.animation = "idle"
	$AnimatedSprite.set_flip_h(left_flip)

	if is_on_floor():
		if Input.is_action_just_pressed('ui_up'):
			velocity.y = -STEP
			$AnimatedSprite.animation = "jump_start"
			jumping = true
		elif jumping == true:
			$AnimatedSprite.animation = "jump_end"
			jumping = false
#	get_input()
	velocity = move_and_slide(velocity, UP)
	pass
