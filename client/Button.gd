extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	Global.username = get_parent().find_node("user").text
	Global.password = get_parent().find_node("passwd").text
	get_tree().change_scene("res://client/Client.tscn")
	pass # Replace with function body.
