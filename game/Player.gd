extends Actor
class_name Player
var STEP = 150
var snap := Vector2(0, 16)
var onLadder := int(0)
var jumping = false
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
		### END DEV ONLY
		if hp > 0:
			# client og code
			if Input.is_action_pressed('block') and attacking != true:
				_block(on_floor)
			elif Input.is_action_just_released('block'):
				_block_finish()
			elif Input.is_action_pressed('attack'):
				attacking = true
			elif Input.is_action_pressed('ui_right') and !attacking:
				velocity.x = STEP
				if on_floor:
					animation = "run"
					sprite.play("run")
				if left_flip == true:
					weapon.position.x = -weapon.position.x
				left_flip = false
			elif Input.is_action_pressed('ui_left') and !attacking:
				velocity.x = -STEP
				if on_floor:
					animation = "run"
					sprite.play("run")
				if left_flip == false:
					weapon.position.x = -weapon.position.x
				left_flip = true
			else:
				velocity.x = 0
				if on_floor and attack_phase == 0:
					animation = "idle"
					sprite.play("idle")

			if attacking == true and attack_phase == 0:
				_attack()
			if (attacking == true or attack_phase > 0) and on_floor:
				velocity.x = 0

			if onLadder == 0:
				if on_floor:
					if Input.is_action_pressed('ui_up'):
						velocity.y = -STEP
						animation = "jump_start"
						sprite.play("jump_start")
						jumping = true
						snap = Vector2(0, 0)
					elif jumping == true:
						sprite.play()
						animation = "jump_end"
						jumping = false
						snap = Vector2(0, 16)
				else:
					if abs(velocity.y) < GRAV:
						animation = "jump_end"
						sprite.play("jump_end")
						sprite.stop()

					velocity.y += GRAV
	#				print(velocity)
			else:
				snap = Vector2(0, 0) if on_floor else Vector2(0, 16)
				animation = "idle"
				sprite.play("idle")
				velocity.y = 0
				if Input.is_action_pressed('ui_up'):
					velocity.y = -STEP
				elif Input.is_action_pressed('ui_down'):
					velocity.y = STEP
		rpc_unreliable_id(1, "set_vars", position, velocity, animation, left_flip, max_hp, hp)
	else:
		#client replica code
		set_vars(
			puppet_position,
			puppet_velocity,
			puppet_animation,
			puppet_left_flip,
			puppet_max_hp,
			puppet_hp)
		sprite.play(animation)

# warning-ignore:unsafe_method_access
	sprite.set_flip_h(left_flip)

	if on_floor and not onLadder and not jumping:
		velocity = move_and_slide_with_snap(velocity, snap, Vector2.UP, true, 1, rad2deg(50))
	else:
		velocity = move_and_slide(velocity, Vector2.UP)
	if not is_network_master():
		puppet_position = position
	else:
		update_coords()
