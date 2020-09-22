extends WindowDialog


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$ItemList2.add_item("Warrior")
	$ItemList2.add_item("Archer")
	$ItemList2.add_item("Wizard")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Create_pressed():
	get_parent().find_node("AudioStreamPlayer").play_confirm()
	get_parent().create_character(Global.username, $LineEdit.text, $ItemList2.get_selected_items()[0])
	self.hide()
