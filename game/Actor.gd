extends KinematicBody2D
class_name Actor

const GRAV = 10
var STEP = 150
master var velocity := Vector2(0, 0)
master var animation := "idle"
master var left_flip := false
master var hp
master var max_hp
master var blocking := false
master var coords := Vector2(0, 0)
var level := 0
var respawn := Global.origin
var displayName := "New Actor"
var jumping = false
var snap := Vector2(0, 16)
puppet var puppet_position := position
puppet var puppet_velocity := velocity
puppet var puppet_animation := animation
puppet var puppet_left_flip := left_flip
puppet var puppet_hp
puppet var puppet_max_hp
puppet var puppet_blocking := blocking
puppet var puppet_coords := coords
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
	puppet_coords = coords
	weapon.disabled = true
	attack_timer = Timer.new()
	attack_timer.set_name(displayName + "AttackTimer")
	attack_timer.set_wait_time(ATK_TIME)
	attack_timer.connect("timeout", self, "_attack_finish")
	add_child(attack_timer)
	sprite.animation = animation

func set_vars(p, a, l, m, h, b):
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

func _attack_finish():
	animation = "idle"
	attack_timer.stop()
	attacking = false
	weapon.disabled = true

remote func _attack():
	attacking = true
	weapon.disabled = false
	if sprite.frame == 4 and animation == "attack_light":
		sprite.set_frame(0)
	animation = "attack_light"
	attack_timer.start()

func _block(on_floor):
	blocking = true
	animation = "block"
	if on_floor:
		velocity.x = 0
		velocity.y = 0

func _block_finish():
	blocking = false
	animation = "idle"

func _walk_left(on_floor):
	velocity.x = -STEP
	if on_floor:
		animation = "run"
	if left_flip == false:
		weapon.position.x = -weapon.position.x
	left_flip = true

func _walk_right(on_floor):
	velocity.x = STEP
	if on_floor:
		animation = "run"
	if left_flip == true:
		weapon.position.x = -weapon.position.x
		left_flip = false

func _hold_still(on_floor):
	velocity.x = 0
	if on_floor and !attacking:
		animation = "idle"

func _jump():
	velocity.y = -STEP
	animation = "jump_start"
	jumping = true
	snap = Vector2(0, 0)

func _fall():
	animation = "jump_end"
	sprite.stop()

func _land():
	animation = "jump_end"
	jumping = false
	snap = Vector2(0, 16)

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
