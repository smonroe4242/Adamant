extends Actor
class_name Player
var climbing := int(0)
### DEV ONLY
#var flying = false
### END DEV ONLY
func _physics_process(_delta):
	var on_floor = is_on_floor()
	if is_network_master():
		### DEV ONLY
#		if Input.is_action_pressed('fly') and not flying:
#			flying = true
#			hitbox.disabled = true
#			hide()
#		elif Input.is_action_pressed('fly') and flying:
#			flying = false
#			hitbox.disabled = false
#			$Camera2D.zoom = Vector2(1, 1)
#			STEP = 150
#			show()
#		if flying:
#			if Input.is_action_pressed('ui_right'):
#				velocity.x = STEP
#			if Input.is_action_pressed('ui_left'):
#				velocity.x = -STEP
#			if Input.is_action_pressed('ui_up'):
#				velocity.y = -STEP
#			if Input.is_action_pressed('ui_down'):
#				velocity.y = STEP
#			if Input.is_action_pressed('attack'):
#				$Camera2D.zoom += Vector2(1, 1)
#				STEP += 100
#			if Input.is_action_pressed('block'):
#				$Camera2D.zoom -= Vector2(1, 1)
#				STEP -= 100
#			velocity = move_and_slide(velocity, Vector2.UP)
#			update_coords()
#			velocity = Vector2(0, 0)
#			return
#		el
		### END DEV ONLY
		if hp > 0:
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
		set_vars(position, animation, left_flip, max_hp, hp, blocking, state, strength, stamina, intellect, wisdom, dexterity, luck)
	else:
		position = puppet_position
		left_flip = puppet_left_flip
		if sprite.animation != puppet_animation:
#			print("Client: ", name, ": animation different: ", animation, " to ", puppet_animation)
			animation = puppet_animation
			sprite.animation = animation
			sprite.play()
		if max_hp != puppet_max_hp or hp != puppet_hp:
			max_hp = puppet_max_hp
			hp = puppet_hp
			overhead.update_display(max_hp, hp)
		if puppet_blocking != blocking:
			if puppet_blocking:
				_block(on_floor)
			else:
				_block_finish()

	sprite.set_flip_h(left_flip)

	if on_floor and not climbing and not jumping:
		velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 1, rad2deg(50))
	else:
		velocity = move_and_slide(velocity, Vector2.UP)
	if not is_network_master():
		puppet_position = position
	else:
		update_coords()
