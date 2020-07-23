extends KinematicBody2D
class_name Actor

const GRAV = 10
master var velocity := Vector2.UP
master var animation := "idle"
master var left_flip := false
master var hp := 100
master var max_hp = 100
var level := 0
var coords = null
var respawn := Vector2(10, 10)
var displayName := "New Actor"
puppet var puppet_position := Vector2()
puppet var puppet_velocity := Vector2()
puppet var puppet_animation := "idle"
puppet var puppet_left_flip := false
puppet var puppet_hp# := 100
puppet var puppet_max_hp# := 100
puppet var puppet_coords
onready var sprite = $AnimatedSprite
onready var hitbox = $CollisionShape2D
onready var weapon = $Weapon/CollisionShape2D
onready var overhead = $OverheadDisplay
const ATK_TIME = 0.5
const DEATH_TIME = 2 # Length of death animation, so we see the whole thing before respawning
var attack_timer
var attacking := false
var attack_phase := 0
signal player_entered

func _ready():
	overhead.position.y -= hitbox.get_shape().get_extents().y
	overhead.title.text = displayName
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
	overhead.update_display(hp, max_hp)

remote func set_vars(p, v, a, l, m, h, c):
	position = p
	velocity = v
	animation = a
	left_flip = l
	max_hp = m
	hp = h
	coords = c

remote func set_puppet_vars(p, v, a, l, m, h, c):
	puppet_position = p
	puppet_velocity = v
	puppet_animation = a
	puppet_left_flip = l
	puppet_max_hp = m
	puppet_hp = h
	puppet_coords = c

func _attack_finish():
	animation = "idle"
	sprite.play(animation)
	attack_timer.stop()
	attacking = false
	attack_phase = 0
	weapon.disabled = true

remote func _attack():
#	print("_attack called for ", name)
	weapon.disabled = false
	attack_phase += 1
	if sprite.frame == 4 and animation == "attack_light":
		sprite.set_frame(0)
	animation = "attack_light"
	sprite.play(animation)
	attack_timer.start()

func set_display_name(user):
	displayName = user

func update_coords():
	var new_coords = Vector2(int(floor(position.x / Global.offsetv.x)), int(floor(position.y / Global.offsetv.y)))
	if new_coords != coords:
		emit_signal("player_entered", coords, new_coords, displayName)
		coords = new_coords

remote func damage(amt):
#	print(name, " damaged (", str(hp - amt), ")", str(get_tree().get_network_unique_id()))
	hp -= amt
	overhead.update_display(hp, max_hp)

remote func die():
	print("DEATH")
	hp = 0
	velocity = Vector2(0, 0)
	overhead.update_display(hp, max_hp)
	animation = "death"
	sprite.play("death")
	sprite.connect("animation_finished", self, "respawn")

func respawn():
	print("Actor respawn ", name)
	sprite.disconnect("animation_finished", self, "respawn")
	hp = max_hp
	overhead.update_display(hp, max_hp)
	if is_network_master():
		position = respawn
		update_coords()
		get_parent().respawn(respawn)
	animation = "idle"
	sprite.play(animation)

func _on_Weapon_body_entered(body):
	if body.has_method("damage") and body.name != name:
		rpc_id(1, "request_damage", body.name)
