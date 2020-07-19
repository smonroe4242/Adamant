extends KinematicBody2D

const GRAV = 20
const STEP = 450
const JUMP = 500
master var velocity := Vector2.UP
master var animation := "idle"
master var left_flip := false
master var hp := 100
master var max_hp = 100
var coords = null
var respawn := Vector2(10, 10)
var jumping := false
var snap := Vector2(0, 16)
var onLadder := int(0)
var displayName := "New Player"
puppet var puppet_position := Vector2()
puppet var puppet_velocity := Vector2()
puppet var puppet_animation := "idle"
puppet var puppet_left_flip := false
puppet var puppet_hp := 100
#puppet var puppet_max_hp := 100
puppet var puppet_coords
onready var sprite = $AnimatedSprite
onready var label = $Label
onready var sword = $Sword
var attack_phase = 0
var attacking = false
var blocking = false
var swung = false
var attack_timer = Timer.new()
const ATK_TIME = 0.5
var death_timer = Timer.new()
const DEATH_TIME = 2.1 # Length of death animation, so we see the whole thing before respawning
signal player_entered

func _ready():
	if is_network_master():
		update_coords()
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
	puppet_hp = hp
	puppet_coords = coords
	label.text = displayName
	attack_timer.set_wait_time(ATK_TIME)
	attack_timer.connect("timeout", self, "_attack_finish")
	add_child(attack_timer)
	death_timer.set_wait_time(DEATH_TIME)
	death_timer.connect("timeout", self, "respawn")
	add_child(death_timer)

# unsafe because network ownership is not checked
# but we had an error with it so come back when we understand
# godot networking better
### TODO master and pupper
remote func set_vars(p, v, a, l, h, c):
	position = p
	velocity = v
	animation = a
	left_flip = l
	hp = h
	coords = c

remote func set_puppet_vars(p, v, a, l, h, c):
	puppet_position = p
	puppet_velocity = v
	puppet_animation = a
	puppet_left_flip = l
	puppet_hp = h
	puppet_coords = c

func _attack_finish():
	attack_phase = 0
	attack_timer.stop()
	attacking = false
	pass

func swing():
	if (swung != true):
		var ids = []
		swung = true
		if is_network_master():
			for b in sword.get_overlapping_areas():
				if b.get_parent().has_method("damage"):
#					print(b.name)
					ids.append(b.get_parent().name)
		rpc_id(1, "request_damage", ids)
	pass

func attack():
	attacking = true
	swung = false
	if attack_phase == 0:
		attack_phase += 1
		if sprite.frame == 3 and animation == "attack_1":
			sprite.set_frame(0)
		animation = "attack_1"
		attack_timer.start()
	pass

func _physics_process(_delta):
	if is_network_master():
		if hp > 0:
			# client og code
			if (animation == "attack_1") and sprite.frame == 2:
				swing()
			if Input.is_action_pressed('block') and attacking != true:
				animation = "block"
				blocking = true
				if is_on_floor():
					velocity.x = 0
					velocity.y = 0
			elif Input.is_action_just_released('block'):
				blocking = false
				animation = "idle"
			elif Input.is_action_pressed('attack'):
				attacking = true
			elif Input.is_action_pressed('ui_right') and !attacking:
				velocity.x = STEP
				if is_on_floor():
					animation = "run"
				left_flip = false
			elif Input.is_action_pressed('ui_left') and !attacking:
				velocity.x = -STEP
				if is_on_floor():
					animation = "run"
				left_flip = true
			else:
				velocity.x = 0
				if is_on_floor() and attack_phase == 0:
					animation = "idle"

			if attacking == true and attack_phase == 0:
				attack()
			if (attacking == true or attack_phase > 0) and is_on_floor():
				velocity.x = 0

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
					velocity.y += GRAV
			else:
				animation = "idle"
				velocity.y = 0
				if Input.is_action_pressed('ui_up'):
					velocity.y = -STEP
				elif Input.is_action_pressed('ui_down'):
					velocity.y = STEP
			rpc_unreliable_id(1, "set_vars", position, velocity, animation, left_flip, hp, coords)
	#		rpc_id(1, "set_vars", position, velocity, animation, left_flip, hp)
	else:
		#client replica code
		set_vars(
			puppet_position,
			puppet_velocity,
			puppet_animation,
			puppet_left_flip,
			puppet_hp,
			puppet_coords)

# warning-ignore:unsafe_method_access
	sprite.set_flip_h(left_flip)
# warning-ignore:unsafe_property_access
	sprite.animation = animation

	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 4, rad2deg(90))
	if not is_network_master():
		puppet_position = position
	else:
		update_coords()

func update_coords():
	var new_coords = Vector2(int(floor(position.x / Global.offsetv.x)), int(floor(position.y / Global.offsetv.y)))
	if new_coords != coords:
		print("moved chunk ", new_coords)
		emit_signal("player_entered", coords, new_coords, displayName)
		coords = new_coords

func set_display_name(user):
	displayName = user

remote func damage(amt):
#	print(name, " damaged (", str(hp - amt), ")", str(get_tree().get_network_unique_id()))
	hp -= amt
	if hp <= 0:
		die()

func die():
#	print("Client: DEAD")
	hp = 0
	animation = "death"
	death_timer.start()

func respawn():
#	print("Client: RESPAWN")
	death_timer.stop()
	position = respawn
	hp = max_hp
	update_coords()
	if is_network_master():
		get_parent().respawn(respawn)
