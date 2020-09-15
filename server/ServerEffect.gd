extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

enum STATUS_TYPES {
	NONE,
	STUN,
	SNARE,
	FREEZE,
	SLEEP,
	SLOW,
	DISARM,
	SILENCE
}

enum DAMAGE_TYPES {
	NONE,
	CHAOS,
	PHYSICAL,
	ICE,
	FIRE,
	LIGHTNING,
	NATURE,
	ARCANE,
	DARK,
	LIGHT
}

var status		= STATUS_TYPES.NONE
var damage		= 0
var damageType	= DAMAGE_TYPES.NONE
var health		= 0
var mana		= 0
var strength	= 0
var stamina		= 0
var intellect	= 0
var wisdom		= 0
var dexterity	= 0
var luck		= 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func apply(actor):
	actor.hp -= damage
	actor.hp += health
	actor.mana += mana
	actor.strength += strength
	actor.stamina += stamina
	actor.intellect += intellect
	actor.wisdom += wisdom
	actor.dexterity += dexterity
	actor.luck += luck

func remove(actor):
	actor.strength -= strength
	actor.stamina -= stamina
	actor.intellect -= intellect
	actor.wisdom -= wisdom
	actor.dexterity -= dexterity
	actor.luck -= luck

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
