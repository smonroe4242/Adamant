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
var hp = 100
var mhp = 100
var attack_phase = 0
var attacking = false
var blocking = false
var swung = false
puppet var puppet_hp = 100
puppet var puppet_mhp = 100
var attack_timer = null

func _ready():
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
# warning-ignore:unsafe_property_access
	label.text = displayName
	attack_timer = Timer.new()
	add_child(attack_timer)
	attack_timer.set_wait_time(0.5)
	attack_timer.connect("timeout", self, "_attack_finish")

# unsafe because network ownership is not checked
# but we had an error with it so come back when we understand
# godot networking better
### TODO master and pupper
remote func set_vars(p, v, a, l, h):
	position = p
	velocity = v
	animation = a
	left_flip = l
	hp = h

remote func set_puppet_vars(p, v, a, l, h):
	puppet_position = p
	puppet_velocity = v
	puppet_animation = a
	puppet_left_flip = l
	puppet_hp = h

func _attack_finish():
	attack_phase = 0
	print("attack phase 0")
	attacking = false
	pass

remote func request_damage(targets):
	var parent = get_parent()
	# a naively trusting damage calculation
	for target in targets:
		var t = parent.get_node(str(target))
		if t == null:
			print("bad")
		else:
			print(t.name)
		t.damage(30)
		if t.hp < 0:
			rpc_id(int(target), "die")

func swing():
	if (swung != true):
		var ids = []
		var sz = 0
		swung = true
		print("DMG")
		if is_network_master():
			print("go")
			for b in $Area2D.get_overlapping_areas():
				print(b.get_parent().name)
				ids.append(b.get_parent().name)
		rpc_id(1, "request_damage", ids)
	pass

func attack():
	attacking = true
	swung = false
	if attack_phase == 0:
		attack_phase += 1
		print("attack")
		if $AnimatedSprite.frame == 3 and animation == "attack_1":
			$AnimatedSprite.set_frame(0)
		animation = "attack_1"
		attack_timer.start()
	pass

func _physics_process(_delta):
	if get_tree().is_network_server():
		# server replica code
		rpc_unreliable("set_puppet_vars", position, velocity, animation, left_flip, hp)
	elif is_network_master() and hp > 0:
		# client og code
		if (animation == "attack_1") and $AnimatedSprite.frame == 2:
			swing()
		velocity.y += GRAV
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
			if !attacking:
				velocity.x = STEP
			if is_on_floor():
				animation = "run"
			left_flip = false
		elif Input.is_action_pressed('ui_left') and !attacking:
			if !attacking:
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
		rpc_unreliable_id(1, "set_vars", position, velocity, animation, left_flip, hp)
	else:
		#client replica code
		set_vars(
			puppet_position,
			puppet_velocity,
			puppet_animation,
			puppet_left_flip,
			puppet_hp)
		mhp = puppet_mhp

# warning-ignore:unsafe_method_access
	sprite.set_flip_h(left_flip)
# warning-ignore:unsafe_property_access
	sprite.animation = animation

	velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 4, rad2deg(90))
	if not is_network_master():
		puppet_position = position

func set_display_name(user):
	displayName = user

remote func damage(amt):
	print(name, " damaged (", str(hp - amt), ")", str(get_tree().get_network_unique_id()))

	if get_tree().is_network_server():
		if (hp - amt < 0):
			print("DEATH")
			die()
			rpc_unreliable("die")
		else:
			rpc_unreliable("damage", amt)
	hp -= amt

remote func die():
	hp = 0
	animation = "death"
