extends MarginContainer

onready var leave = $LeaveButton

func _process(_delta):
	if leave.pressed:
		get_tree().network_peer = null
		get_tree().quit(0)
