extends ServerActor

enum CLASSES {
	WARRIOR,
	ARCHER,
	WIZARD
}

var testaura
var classtype = CLASSES.WARRIOR
var char_selection = 0

func _init():
	var _aura = load("res://server/ServerAura.gd").new()
	var _effect = load("res://server/ServerEffect.gd").new()
	_aura.duration = 3.0
	_effect.stamina = 5
	_aura.effect = _effect
	effects.push_back(_aura)
	print("Before: ", self.stamina)
	_aura.apply(self)
	print("After: ", self.stamina)
	testaura = _aura

func _ready():
	self.add_child(testaura)

func _physics_process(_delta):
	var new_coords = Vector2(int(floor(position.x / Global.offsetv.x)), int(floor(position.y / Global.offsetv.y)))
	if new_coords != coords:
		coords = new_coords

	for chunk in Global.get_area(coords):
		if actor_map.has(chunk):
			for id in actor_map[chunk].keys():
				#if int(id) != int(name):
				set_puppet_vars(id, position, animation, left_flip, max_hp, hp, blocking, state, strength, stamina, intellect, wisdom, dexterity, luck)
	puppet_position = position
	puppet_animation = animation
	puppet_left_flip = left_flip
	puppet_max_hp = max_hp
	puppet_hp = hp
	puppet_blocking = blocking
	puppet_strength = strength
	puppet_stamina = stamina
	puppet_intellect = intellect
	puppet_wisdom = wisdom
	puppet_dexterity = dexterity
	puppet_luck = luck

func die():
	print("Server: Player DEATH")
	hp = 0
	animation = "death"
