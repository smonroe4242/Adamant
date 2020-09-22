extends Node2D

onready var health = $Grid/Center/HealthBar
onready var title = $Grid/Title
func _ready():
	pass
	#if health.value != health.max_value:
		#health.hide()

func _process(delta):
	if not Global.player_node == null:
		health.max_value = Global.player_node.attributes.max_hp
		health.set_value(Global.player_node.attributes.hp)
		title.text = str(Global.player_node.attributes.hp) + "/" + str(Global.player_node.attributes.max_hp)

func update_display(max_hp, hp):
	health.max_value = max_hp
	health.value = hp
	if hp < max_hp:
		health.show()
	else:
		health.hide()
