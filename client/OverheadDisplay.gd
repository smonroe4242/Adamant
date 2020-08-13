extends Node2D

onready var health = $Grid/Center/HealthBar
onready var title = $Grid/Title

func _ready():
	if health.value != health.max_value:
		health.hide()

func update_title(text, lvl):
	title.text = text + " LvL" + str(lvl)

func update_healthbar(max_hp, hp):
	health.max_value = max_hp
	health.value = hp
	if hp < max_hp:
		health.show()
	else:
		health.hide()
