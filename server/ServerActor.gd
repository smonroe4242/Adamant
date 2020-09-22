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
var classtype = 0
remote var velocity := Vector2(0, 0)
remote var animation := "idle"
remote var left_flip := false

#!
remote var attributes = {
	'hp': 100,
	'max_hp': 100,
	'mana': 0,
	'max_mana': 0,
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
#!

remote var mana := 0
remote var max_mana := 0
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

remote var puppet_mana := mana
remote var puppet_max_mana := max_mana
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
	
	#!
	for key in attributes.keys():
		puppet_attributes[key] = attributes[key]
	#!
	
	puppet_state = state
	puppet_coords = coords
	puppet_effects = effects
### TODO master and pupper
#remote
func set_puppet_vars(id, p, a, l, b, s, new_attributes):
	if puppet_position != position:
#		print("Server: telling ", id, "that position changed: ", p, ", ", position, ", ", puppet_position)
		rset_unreliable_id(id, 'puppet_position', p)
	if puppet_animation != animation:
#		print("Server: telling ", id, "that animation changed from ", puppet_animation, " to ", a)
		rset_id(id, 'puppet_animation', a)
	if puppet_left_flip != left_flip:
#		print("Server: telling ", id, "that left_flip changed")
		rset_id(id, 'puppet_left_flip', l)
	if puppet_blocking != blocking:
#		print("Server: telling ", id, "that blocking changed to ", b)
		rset_id(id, 'puppet_blocking', b)
	if puppet_state != state:
		rset_id(id, 'puppet_state', s)
		
	#!
	for key in puppet_attributes.keys():
		if attributes[key] != puppet_attributes[key]:
			rset_id(id, 'puppet_attributes', new_attributes)
			print("NEW_STATS_OBJ: changing " + key)
	#!

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
	if (attributes.hp - amt <= 0):
		attributes.hp = 0
		die()
		rpc("damage", attributes.hp)
		rpc("die")
	else:
		attributes.hp -= amt
		rpc("damage", amt)

func die():
	# Implemented in subclasses
	pass

func _process(delta):
	var to_remove = []
	for i in effects.size():
		if effects[i].finished == true:
			effects[i].remove(self)
			to_remove.push_front(i)
	for i in to_remove:
		remove_child(effects[i])
		effects.remove(i)
	#print("name: ", name, " str: ", strength)

func evaluate_stats():
	attributes.max_hp = attributes.stamina * 10
	if attributes.max_hp < attributes.hp:
		attributes.hp = attributes.max_hp
