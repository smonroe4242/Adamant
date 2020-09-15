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
master var hp
master var max_hp
remote var strength
remote var stamina
remote var intellect
remote var wisdom
remote var dexterity
remote var luck
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
remote var puppet_hp
remote var puppet_max_hp
remote var puppet_strength
remote var puppet_stamina
remote var puppet_intellect
remote var puppet_wisdom
remote var puppet_dexterity
remote var puppet_luck
remote var puppet_blocking := blocking
remote var puppet_coords := coords
remote var puppet_state := state
onready var sprite = $AnimatedSprite
onready var hitbox = $CollisionShape2D
onready var weapon = $Weapon/CollisionShape2D
onready var overhead = $OverheadDisplay
const ATK_TIME = 0.5
const DEATH_TIME = 2
var attack_timer
var attacking := false
signal player_entered

func _ready():
	overhead.position.y -= hitbox.get_shape().get_extents().y
	overhead.title.text = displayName
	overhead.update_display(max_hp, hp)
	coords = Vector2(int(floor(position.x / Global.offsetv.x)), int(floor(position.y / Global.offsetv.y)))
	if is_network_master():
		get_parent().rpc_id(1, "get_local_actors", coords, displayName)
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
	puppet_hp = hp
	puppet_max_hp = max_hp
	puppet_strength = strength
	puppet_stamina = stamina
	puppet_intellect = intellect
	puppet_wisdom = wisdom
	puppet_dexterity = dexterity
	puppet_luck = luck
	puppet_coords = coords
	puppet_state = state
	weapon.disabled = true
	attack_timer = Timer.new()
	attack_timer.set_name(displayName + "AttackTimer")
	attack_timer.set_wait_time(ATK_TIME)
	attack_timer.connect("timeout", self, "_attack_finish")
	add_child(attack_timer)
	sprite.animation = animation

func set_vars(p, a, l, m, h, b, s, _strength, _stamina, _intellect, _wisdom, _dexterity, _luck):
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
	if m != puppet_max_hp:
		puppet_max_hp = m
#		print("Client: ", name, ": max_hp changed")
		rset_id(1, 'max_hp', m)
	if h != puppet_hp:
		puppet_hp = h
#		print("Client: ", name, ": hp changed")
		rset_id(1, 'hp', h)
	if b != puppet_blocking:
		puppet_blocking = b
#		print("Client: ", name, ": blocking changed")
		rset_id(1, 'blocking', b)
	#stats get set to puppet vars as they are controlled by server???
	if _strength != puppet_strength:
		print("Client: ", name, " changed strength: ", _strength, " -> ", puppet_strength)
		strength = puppet_strength
		rset_id(1, 'strength', puppet_strength)
	if _stamina != puppet_stamina:
		stamina = puppet_stamina
		rset_id(1, 'stamina', puppet_stamina)
	if _intellect != puppet_intellect:
		intellect = puppet_intellect
		rset_id(1, 'intellect', puppet_intellect)
	if _wisdom != puppet_wisdom:
		wisdom = puppet_wisdom
		rset_id(1, 'wisdom', puppet_wisdom)
	if _dexterity != puppet_dexterity:
		dexterity = puppet_dexterity
		rset_id(1, 'dexterity', puppet_dexterity)
	if _luck != puppet_luck:
		luck = puppet_luck
		rset_id(1, 'luck', puppet_luck)
		

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
		hp -= amt
		overhead.update_display(max_hp, hp)

remote func die():
	print("Client: DEATH")
	hp = 0
	velocity = Vector2(0, 0)
	overhead.update_display(max_hp, hp)
	animation = "death"
	sprite.connect("animation_finished", self, "respawn")

func respawn():
	print("Client: Actor respawn ", name)
	sprite.disconnect("animation_finished", self, "respawn")
	hp = max_hp
	overhead.update_display(max_hp, hp)
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

func _process(delta):
	#print(puppet_strength)
	pass
