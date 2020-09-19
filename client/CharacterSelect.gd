extends WindowDialog


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Select_pressed():
	get_parent().select_character(Global.username, $ItemList.get_selected_items()[0])
	self.hide()
	pass # Replace with function body.


func _on_New_pressed():
	self.hide()
	get_parent().find_node("CharCreate").show()
	pass # Replace with function body.
