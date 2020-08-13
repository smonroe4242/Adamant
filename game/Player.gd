extends Actor
class_name Player
var climbing := int(0)
var xp = 0
remote var puppet_xp : int setget set_xp
remote var puppet_level : int setget set_lvl

func set_xp(new_xp):
	print("SET XP: ", name, ": ", xp, " -> ", new_xp, " -> ", puppet_xp)
	xp = new_xp
	puppet_xp = new_xp

func set_lvl(new_lvl):
	print("SET LVL: ", name, ": ", level, " -> ", new_lvl, " -> ", puppet_level)
	level = new_lvl
	puppet_level = new_lvl
	overhead.update_title(displayName, level)

### DEV ONLY
onready var cam = $Camera2D
var flying = false
### END DEV ONLY
func _physics_process(_delta):
	var on_floor = is_on_floor()
	if is_network_master():
		### DEV ONLY
		if Input.is_action_pressed('fly') and not flying:
			flying = true
			hitbox.disabled = true
			hide()
		elif Input.is_action_pressed('fly') and flying:
			flying = false
			hitbox.disabled = false
			cam.zoom = Vector2(1, 1)
			STEP = 150
			show()
		if flying:
			if Input.is_action_pressed('ui_right'):
				velocity.x = STEP
			if Input.is_action_pressed('ui_left'):
				velocity.x = -STEP
			if Input.is_action_pressed('ui_up'):
				velocity.y = -STEP
			if Input.is_action_pressed('ui_down'):
				velocity.y = STEP
			if Input.is_action_pressed('attack'):
				cam.zoom += Vector2(1, 1)
				STEP += 100
			if Input.is_action_pressed('block'):
				cam.zoom -= Vector2(1, 1)
				STEP -= 100
			velocity = move_and_slide(velocity, Vector2.UP)
			update_coords()
			velocity = Vector2(0, 0)
			return

		### END DEV ONLY
		elif hp > 0:
			# client og code
			if Input.is_action_pressed('block') and attacking != true:
				_block(on_floor)
			elif Input.is_action_just_released('block'):
				_block_finish()
			elif Input.is_action_pressed('attack') and not attacking:
				_attack()
			elif Input.is_action_pressed('ui_right') and not attacking:
				_walk_right(on_floor)
			elif Input.is_action_pressed('ui_left') and not attacking:
				_walk_left(on_floor)
			else:
				_hold_still(on_floor)

			if attacking and on_floor:
				velocity.x = 0

			if not climbing:
				if on_floor:
					if Input.is_action_pressed('ui_up'):
						_jump()
					elif jumping == true:
						_land()
				else:
					if velocity.y > 0:
						_fall()
					velocity.y += GRAV
			else:
				snap = Vector2(0, 0) if on_floor else Vector2(0, 16)
				animation = "idle"
				velocity.y = 0
				if Input.is_action_pressed('ui_up'):
					velocity.y = -STEP
				elif Input.is_action_pressed('ui_down'):
					velocity.y = STEP

		if sprite.animation != animation:
			sprite.play(animation)
		set_vars()
	else:
		be_a_replica(on_floor)

	sprite.set_flip_h(left_flip)

	if on_floor and not climbing and not jumping:
		velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 1, rad2deg(50))
	else:
		velocity = move_and_slide(velocity, Vector2.UP)
	if not is_network_master():
		puppet_position = position
	else:
		update_coords()


func respawn():
	print("Client: Actor respawn ", name)
	sprite.disconnect("animation_finished", self, "respawn")
	hp = max_hp
	overhead.update_healthbar(max_hp, hp)
	if is_network_master():
		position = respawn_point
		update_coords()
		get_parent().respawn(respawn_point)
	animation = "idle"
