extends Node2D

onready var progress = $CanvasLayer/TextureProgress
onready var label = $CanvasLayer/Label
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not Global.player_node == null:
		progress.max_value = Global.player_node.max_hp
		progress.set_value(Global.player_node.hp)
		label.text = str(Global.player_node.hp) + "/" + str(Global.player_node.max_hp)
