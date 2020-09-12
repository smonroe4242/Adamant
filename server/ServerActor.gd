extends KinematicBody2D
class_name ServerActor

enum STATES {
	STATE_IDLE,
	STATE_MOVE,
	STATE_DEAD,
	STATE_ATTACK,
	STATE_BLOCK,
	STATE_CLIMB,
	STATE_AIR
}

var actor_map
var monster_map
var level := 0
var username
remote var velocity := Vector2(0, 0)
remote var animation := "idle"
remote var left_flip := false

remote var hp := 59
remote var max_hp := 59
remote var strength := 10
remote var stamina := 10
remote var intellect := 10
remote var wisdom := 10
remote var dexterity := 10
remote var luck := 10
remote var state = STATES.STATE_IDLE

remote var blocking := false
remote var coords

remote var puppet_position := position
remote var puppet_velocity := velocity
remote var puppet_animation := animation
remote var puppet_left_flip := left_flip

remote var puppet_hp := hp
remote var puppet_max_hp := max_hp
remote var puppet_strength := strength
remote var puppet_stamina := stamina
remote var puppet_intellect := intellect
remote var puppet_wisdom := wisdom
remote var puppet_dexterity := dexterity
remote var puppet_luck := luck
remote var puppet_state = state

remote var puppet_blocking := blocking
remote var puppet_coords

remote var effects := []
remote var puppet_effects := []

func _ready():
	coords = position / Global.offsetv
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
	puppet_max_hp = max_hp
	puppet_hp = hp
	puppet_strength = strength
	puppet_stamina = stamina
	puppet_intellect = intellect
	puppet_wisdom = wisdom
	puppet_dexterity = dexterity
	puppet_luck = luck
	puppet_state = state
	puppet_coords = coords
### TODO master and pupper
#remote
func set_puppet_vars(id, p, a, l, m, h, b, s, _strength, _stamina, _intellect, _wisdom, _dexterity, _luck):
	if puppet_position != position:
#		print("Server: telling ", id, "that position changed: ", p, ", ", position, ", ", puppet_position)
		rset_unreliable_id(id, 'puppet_position', p)
	if puppet_animation != animation:
#		print("Server: telling ", id, "that animation changed from ", puppet_animation, " to ", a)
		rset_id(id, 'puppet_animation', a)
	if puppet_left_flip != left_flip:
#		print("Server: telling ", id, "that left_flip changed")
		rset_id(id, 'puppet_left_flip', l)
	if puppet_max_hp != max_hp:
#		print("Server: telling ", id, "that max_hp changed to ", m)
		rset_id(id, 'puppet_max_hp', m)
	if puppet_hp != hp:
#		print("Server: telling ", id, "that hp changed to ", h)
		rset_id(id, 'puppet_hp', h)
	if puppet_blocking != blocking:
#		print("Server: telling ", id, "that blocking changed to ", b)
		rset_id(id, 'puppet_blocking', b)
	if puppet_state != state:
		rset_id(id, 'puppet_state', s)
	if puppet_strength != strength:
		rset_id(id, 'puppet_strength', _strength)
	if puppet_stamina != stamina:
		rset_id(id, 'puppet_stamina', _stamina)
	if puppet_intellect != intellect:
		rset_id(id, 'puppet_intellect', _intellect)
	if puppet_wisdom != wisdom:
		rset_id(id, 'puppet_wisdom', _wisdom)
	if puppet_dexterity != dexterity:
		rset_id(id, 'puppet_dexterity', _dexterity)
	if puppet_luck != luck:
		rset_id(id, 'puppet_luck', _luck)

remote func request_damage(target):
	# a naively trusting damage calculation
	var child = get_parent().get_node(str(target))
	if not child == null:
		if child.blocking == false:
			print("Server: damaging child: ", child.name)
			child.damage(30)
	else:
		print("Server: Child ", target, " was not found")

func damage(amt):
	if (hp - amt <= 0):
		hp = 0
		die()
		rpc("damage", hp)
		rpc("die")
	else:
		hp -= amt
		rpc("damage", amt)

func die():
	# Implemented in subclasses
	pass
