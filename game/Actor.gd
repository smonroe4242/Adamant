extends KinematicBody2D
class_name Actor

enum {
	STATE_IDLE,
	STATE_MOVE,
	STATE_DEAD,
	STATE_ATTACK,
	STATE_BLOCK,
	STATE_CLIMB,
	STATE_AIR
}
const GRAV = 10
var STEP = 150
master var velocity := Vector2(0, 0)
master var animation := "idle"
master var left_flip := false

remote var attributes = {
	'hp': 100,
	'max_hp': 100,
	'mana': 0,
	'max_mana': 100,
	'strength': 10,
	'stamina': 10,
	'intellect': 10,
	'wisdom': 10,
	'dexterity': 10,
	'luck': 10,
	'classtype': 0
}
remote var puppet_attributes = {
	'hp': 100,
	'max_hp': 100,
	'mana': 0,
	'max_mana': 100,
	'strength': 10,
	'stamina': 10,
	'intellect': 10,
	'wisdom': 10,
	'dexterity': 10,
	'luck': 10,
	'classtype': 0
}
remote var classtype = 0 #SET TO 1 FOR ARCHER
master var blocking := false
master var coords := Vector2(0, 0)
master var state := STATE_IDLE
var level := 0
var respawn := Global.origin
var displayName := "New Actor"
var jumping = false
var snap := Vector2(0, 16)
remote var puppet_position := position
remote var puppet_velocity := velocity
remote var puppet_animation := animation
remote var puppet_left_flip := left_flip
remote var puppet_blocking := blocking
remote var puppet_coords := coords
remote var puppet_state := state
onready var sprite = $AnimatedSprite
onready var hitbox = $CollisionShape2D
onready var weapon = $Weapon/CollisionShape2D
onready var overhead = $OverheadDisplay
var archer_frames = preload("res://assets/Archer/archer_frames.tres")
const ATK_TIME = 0.5
const DEATH_TIME = 2
var attack_timer
var attacking := false
signal player_entered

func _ready():
	overhead.position.y -= hitbox.get_shape().get_extents().y
	overhead.title.text = displayName
	overhead.update_display(attributes.max_hp, attributes.hp)
	coords = Vector2(int(floor(position.x / Global.offsetv.x)), int(floor(position.y / Global.offsetv.y)))
	if is_network_master():
		get_parent().rpc_id(1, "get_local_actors", coords, displayName)
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
	
	for key in attributes.keys():
		puppet_attributes[key] = attributes[key]
	
	puppet_coords = coords
	puppet_state = state
	weapon.disabled = true
	attack_timer = Timer.new()
	attack_timer.set_name(displayName + "AttackTimer")
	attack_timer.set_wait_time(ATK_TIME)
	attack_timer.connect("timeout", self, "_attack_finish")
	add_child(attack_timer)
	sprite.animation = animation
	if classtype == 1:
		sprite.set_sprite_frames(archer_frames)
		sprite.set_offset(sprite.get_offset() - Vector2(0,20))
		#$AnimatedSprite.hide()

func set_vars(p, a, l, b, s, new_attributes):
	if s != puppet_state:
		puppet_state = s
		rset_unreliable_id(1, 'state', s)
	if p != puppet_position:
		puppet_position = p
#		print("Client: ", name, ": position changed")
		rset_unreliable_id(1, 'position', Vector2(int(p.x), int(p.y)))
	if a != puppet_animation:
#		print("Client: ", name, ": animation changed from ", puppet_animation, " to ", a)
		puppet_animation = a
		rset_id(1, 'animation', a)
	if l != puppet_left_flip:
		puppet_left_flip = l
#		print("Client: ", name, ": left_flip changed")
		rset_id(1, 'left_flip', l)
	if b != puppet_blocking:
		puppet_blocking = b
#		print("Client: ", name, ": blocking changed")
		rset_id(1, 'blocking', b)
		
	for key in attributes.keys():
		if new_attributes[key] != puppet_attributes[key]:
			print("key: ", key)
			attributes[key] = puppet_attributes[key]
			rset_id(1, 'attributes', puppet_attributes)
			print("NEW_STATS_OBJ: Updated ", key)

func _attack_finish():
	animation = "idle"
	attack_timer.stop()
	attacking = false
	weapon.disabled = true
	state = STATE_IDLE

remote func _attack():
	attacking = true
	weapon.disabled = false
	if sprite.frame == 4 and animation == "attack_light":
		sprite.set_frame(0)
	animation = "attack_light"
	attack_timer.start()
	state = STATE_ATTACK

func _block(on_floor):
	blocking = true
	animation = "block"
	if on_floor:
		velocity.x = 0
		velocity.y = 0
	state = STATE_BLOCK

func _block_finish():
	blocking = false
	animation = "idle"
	state = STATE_IDLE

func _walk_left(on_floor):
	velocity.x = -STEP
	if on_floor:
		animation = "run"
	if left_flip == false:
		weapon.position.x = -weapon.position.x
	left_flip = true
	state = STATE_MOVE

func _walk_right(on_floor):
	velocity.x = STEP
	if on_floor:
		animation = "run"
	if left_flip == true:
		weapon.position.x = -weapon.position.x
		left_flip = false
	state = STATE_MOVE

func _hold_still(on_floor):
	velocity.x = 0
	if on_floor and !attacking:
		animation = "idle"
		state = STATE_IDLE

func _jump():
	velocity.y = -STEP
	animation = "jump_start"
	jumping = true
	snap = Vector2(0, 0)
	state = STATE_AIR

func _fall():
	animation = "jump_end"
	sprite.stop()
	state = STATE_AIR

func _land():
	animation = "jump_end"
	jumping = false
	snap = Vector2(0, 16)
	state = STATE_IDLE

func set_display_name(user):
	displayName = user

func update_coords():
	var new_coords = Vector2(int(floor(position.x / Global.offsetv.x)), int(floor(position.y / Global.offsetv.y)))
	if new_coords != coords:
		print("Client: CROSSED CHUNK ", new_coords)
		emit_signal("player_entered", coords, new_coords, displayName)
		coords = new_coords

remote func damage(amt):
	if not blocking:
		attributes.hp -= amt
		overhead.update_display(attributes.max_hp, attributes.hp)

remote func die():
	print("Client: DEATH")
	attributes.hp = 0
	velocity = Vector2(0, 0)
	overhead.update_display(attributes.max_hp, attributes.hp)
	animation = "death"
	sprite.connect("animation_finished", self, "respawn")

func respawn():
	print("Client: Actor respawn ", name)
	sprite.disconnect("animation_finished", self, "respawn")
	attributes.hp = attributes.max_hp
	overhead.update_display(attributes.max_hp, attributes.hp)
	if is_network_master():
		position = respawn
		update_coords()
		get_parent().respawn(respawn)
	animation = "idle"

func _on_Weapon_body_entered(body):
	print("Client: ", name, " had weapon contact")
	if body.has_method("damage") and body.name != name:
		print("Client:  with actor ", body.name)
		rpc_id(1, "request_damage", body.name)

func _enter_tree():
	pass
