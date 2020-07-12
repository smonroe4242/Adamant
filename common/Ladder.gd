extends Area2D

class_name Ladder

var height = 1

func _ready():
	#print("Ladder on scene")
	pass

func _init(size):
	pass
	print("Making ladder size ", size)
	height = size
#	position.x = x
#	position.y = y
#	get_node(".").call_deferred("add_child", Sprite.new())

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_MyLadder_body_entered(body):
	get_parent().get_node(body.name).onLadder = true

func _on_MyLadder_body_exited(body):
	get_parent().get_node(body.name).onLadder = false
