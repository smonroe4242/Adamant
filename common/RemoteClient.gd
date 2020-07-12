extends Node2D

remote func _update_client_position(new_pos):
	print("I got called on the server!: ", new_pos)
	position = new_pos
	pass

func _ready():
	print("I'm aliveeeeeee!!!")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
