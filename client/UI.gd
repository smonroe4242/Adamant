extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var win = preload("res://assets/UI/window.tscn")

var popups = [
	win.instance(),
	win.instance(),
	win.instance()
]
enum {
	WELCOME,
	CHAR_SHEET,
	SYSTEM
}

# Called when the node enters the scene tree for the first time.
func _ready():
	#var welcome_win = win.instance()
	popups[WELCOME].set_title("Welcome!")
	popups[WELCOME].find_node("Text").text = "Welcome to the game!"
	#popups.push_back(welcome_win)
	
	popups[CHAR_SHEET].set_title("Character Sheet")
	
	popups[SYSTEM].set_title("System")
	popups[SYSTEM].find_node("ItemList").connect('item_selected', self, 'system_select_item')
	
	add_child(popups[WELCOME])
	add_child(popups[CHAR_SHEET])
	add_child(popups[SYSTEM])
	popups[WELCOME].popup()
	pass # Replace with function body.
	
func _character_sheet(p):
	var list = popups[CHAR_SHEET].find_node("ItemList")
	list.clear()
	list.add_item("Name     | " + p.displayName)
	list.add_item("Health   | " + str(p.hp))
	list.add_item("Strength | " + str(p.strength))
	list.add_item("Stamina | " + str(p.stamina))
	list.add_item("Intellect| " + str(p.intellect))
	list.add_item("Wisdom   | " + str(p.wisdom))
	list.add_item("Dexterity| " + str(p.dexterity))
	list.add_item("Luck     | " + str(p.luck))
	popups[CHAR_SHEET].popup()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _system():
	var list = popups[SYSTEM].find_node("ItemList")
	list.clear()
	list.add_item("About")
	list.add_item("Logout")
	list.add_item("Exit")
	popups[SYSTEM].popup()

func _on_TextureButton_pressed():
	_character_sheet(Global.player_node)
	pass # Replace with function body.

func system_select_item(item):
	if item == 2:
		get_tree().network_peer = null
		get_tree().quit(0)
	print("callback")
	pass

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		_system()
