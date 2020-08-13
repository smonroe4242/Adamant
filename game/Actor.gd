extends KinematicBody2D
class_name Actor

const GRAV : int = 10
var STEP : int = 150
master var velocity : Vector2 = Vector2(0, 0)
master var animation : String = "idle"
master var left_flip : bool = false
master var hp : int = 100
master var max_hp : int = 100
master var blocking : bool = false
master var coords : Vector2 = Vector2(0, 0)
var level : int = 0
var respawn_point : Vector2 = Global.origin
var displayName : String = "New Actor"
var jumping : bool = false
var snap : Vector2 = Vector2(0, 16)
puppet var puppet_position : Vector2 = position
puppet var puppet_animation : String = animation
puppet var puppet_left_flip : bool = left_flip
puppet var puppet_hp : int
puppet var puppet_max_hp : int
puppet var puppet_blocking : bool = blocking
puppet var puppet_coords : Vector2 = coords

onready var sprite = $AnimatedSprite
onready var hitbox = $CollisionShape2D
onready var weapon = $Weapon/CollisionShape2D
onready var overhead = $OverheadDisplay
const ATK_TIME : float = 0.5
const DEATH_TIME : int = 2
var attack_timer : Timer
var attacking : bool = false
signal player_entered

func _ready() -> void:
	overhead.position.y -= hitbox.get_shape().get_extents().y
	overhead.update_title(displayName, level)
	overhead.update_healthbar(max_hp, hp)
	coords = Vector2(floor(position.x / Global.offsetv.x), floor(position.y / Global.offsetv.y))
	if is_network_master():
		get_parent().rpc_id(1, "get_local_actors", coords)
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

func set_vars() -> void:
	var int_position = Vector2(floor(position.x), floor(position.y))
	if int_position != puppet_position:
		puppet_position = int_position
#		print("Client: ", name, ": position changed")
		rset_unreliable_id(1, 'position', int_position)
	if animation != puppet_animation:
#		print("Client: ", name, ": animation changed from ", puppet_animation, " to ", animation)
		puppet_animation = animation
		rset_id(1, 'animation', animation)
	if left_flip != puppet_left_flip:
		puppet_left_flip = left_flip
#		print("Client: ", name, ": left_flip changed")
		rset_id(1, 'left_flip', left_flip)
	if max_hp != puppet_max_hp:
		puppet_max_hp = max_hp
#		print("Client: ", name, ": max_hp changed")
		rset_id(1, 'max_hp', max_hp)
	if hp != puppet_hp:
		puppet_hp = hp
#		print("Client: ", name, ": hp changed")
		rset_id(1, 'hp', hp)
	if blocking != puppet_blocking:
		puppet_blocking = blocking
#		print("Client: ", name, ": blocking changed")
		rset_id(1, 'blocking', blocking)

func be_a_replica(on_floor) -> void:
	position = puppet_position
	if left_flip != puppet_left_flip:
		left_flip = puppet_left_flip
		sprite.set_flip_h(left_flip)
	if sprite.animation != puppet_animation:
		animation = puppet_animation
		sprite.play(animation)
	if hp != puppet_hp or max_hp != puppet_max_hp:
		max_hp = puppet_max_hp
		hp = puppet_hp
		overhead.update_healthbar(max_hp, hp)
	if puppet_blocking != blocking:
		if puppet_blocking:
			_block(on_floor)
		else:
			_block_finish()

func _attack_finish() -> void:
	animation = "idle"
	attack_timer.stop()
	attacking = false
	weapon.disabled = true

remote func _attack() -> void:
	attacking = true
	weapon.disabled = false
	if sprite.frame == 4 and animation == "attack_light":
		sprite.set_frame(0)
	animation = "attack_light"
	attack_timer.start()

func _block(on_floor: bool) -> void:
	blocking = true
	animation = "block"
	if on_floor:
		velocity.x = 0
		velocity.y = 0

func _block_finish() -> void:
	blocking = false
	animation = "idle"

func _walk_left(on_floor: bool) -> void:
	velocity.x = -STEP
	if on_floor:
		animation = "run"
	if left_flip == false:
		weapon.position.x = -weapon.position.x
	left_flip = true

func _walk_right(on_floor: bool) -> void:
	velocity.x = STEP
	if on_floor:
		animation = "run"
	if left_flip == true:
		weapon.position.x = -weapon.position.x
		left_flip = false

func _hold_still(on_floor: bool) -> void:
	velocity.x = 0
	if on_floor and !attacking:
		animation = "idle"

func _jump() -> void:
	velocity.y = -STEP
	animation = "jump_start"
	jumping = true
	snap = Vector2(0, 0)

func _fall() -> void:
	animation = "jump_end"
	sprite.stop()

func _land() -> void:
	animation = "jump_end"
	jumping = false
	snap = Vector2(0, 16)

func set_display_name(user : String) -> void:
	displayName = user

func update_display_name() -> void:
	overhead.update_title(displayName, level)

func update_coords() -> void:
	var new_coords = Vector2(floor(position.x / Global.offsetv.x), floor(position.y / Global.offsetv.y))
	if new_coords != coords:
		print("Client: CROSSED CHUNK ", new_coords)
		emit_signal("player_entered", coords, new_coords)
		coords = new_coords

remote func damage(amt: int) -> void:
	if not blocking:
		hp -= amt
		overhead.update_healthbar(max_hp, hp)

remote func die() -> void:
	print("Client: DEATH")
	hp = 0
	velocity = Vector2(0, 0)
	overhead.update_healthbar(max_hp, hp)
	animation = "death"
	if has_method('respawn'):
		sprite.connect("animation_finished", self, "respawn")

func _on_Weapon_body_entered(body) -> void:
	if body.has_method("damage") and body.name != name:
		print("Client:  with actor ", body.name)
		rpc_id(1, "request_damage", body.name)
