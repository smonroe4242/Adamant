extends KinematicBody2D

const UP = Vector2(0, -1)
const GRAV = 20
const STEP = 800
const JUMP = -20
var velocity = Vector2.UP

func _physics_process(delta):
	velocity.y += GRAV
	if Input.is_action_pressed('ui_right'):
		velocity.x = STEP
	elif Input.is_action_pressed('ui_left'):
		velocity.x = -STEP
	else:
		velocity.x = 0

	if is_on_floor():
		if Input.is_action_just_pressed('ui_up'):
			velocity.y = -STEP
#	get_input()
	velocity = move_and_slide(velocity, UP)
	pass
