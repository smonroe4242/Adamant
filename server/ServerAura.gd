extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var displayName = ""
var prefix = ""
var affix = ""
var persistent = true
var duration = 0.0
var period = 0.0
var chance = 0.0
var effect = null
var finished = false

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Here!")
	pass # Replace with function body.

func apply(actor):
	print("Apply!")
	if persistent == true:
		effect.apply(actor)
	print(actor.attributes.stamina)

func process(actor):
	if persistent != true:
		if randi() % 100 < (int(chance * 100)):
			effect.apply(actor)

func remove(actor):
	if persistent == true:
		effect.remove(actor)
		actor.evaluate_stats()
		print("Removed!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if duration > 0.0:
		if duration > delta:
			duration -= delta
		else:
			print("Remove!")
			finished = true
	pass
