extends Node2D

onready var progress = $CanvasLayer/TextureProgress
onready var label = $CanvasLayer/Label
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var player = Global.get_player()
	if not player == null:
		progress.max_value = player.max_hp
		progress.set_value(player.hp)
		label.text = str(player.hp) + "/" + str(player.max_hp)
