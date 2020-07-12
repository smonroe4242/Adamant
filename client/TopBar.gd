extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(_delta):
	if $LeaveButton.pressed:
		get_tree().network_peer = null
		OS.kill(OS.get_process_id())
#		get_tree().change_scene("res://game/Entry.tscn")
#		get_tree().get_root().print_tree_pretty()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
