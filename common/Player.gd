extends KinematicBody2D

const UP = Vector2(0, -1)
const GRAV = 20
const STEP = 300
const JUMP = -25
var velocity = Vector2.UP
puppet var puppet_pos := Vector2()
puppet var puppet_vel := Vector2()
var onLadder = false

func _ready():
	puppet_pos = position

func _physics_process(_delta):
#	if self.name != str(get_tree().get_network_unique_id()):
#		pass
	#var velocity = Vector2()
	if is_network_master():
		#velocity = Vector2()
		velocity.y += GRAV
		if Input.is_action_pressed('ui_right'):
			velocity.x = STEP
		elif Input.is_action_pressed('ui_left'):
			velocity.x = -STEP
		else:
			velocity.x = 0

		if onLadder:
			velocity.y = 0
			if Input.is_action_pressed('ui_up'):
				velocity.y = -STEP
			elif Input.is_action_pressed('ui_down'):
				velocity.y = STEP

		if Input.is_action_just_pressed('ui_up'):
			if is_on_floor():
				velocity.y = GRAV * JUMP
				
		rset_unreliable("puppet_pos", position)
		rset_unreliable("puppet_vel", velocity)
	else:
		position = puppet_pos
		velocity = puppet_vel

	velocity = move_and_slide(velocity, UP)
	if not is_network_master():
		puppet_pos = position
