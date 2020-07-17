extends MarginContainer

func _on_LeaveButton_pressed():
	get_tree().network_peer = null
	get_tree().quit(0)
