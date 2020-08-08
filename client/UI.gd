extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var win = preload("res://assets/UI/window.tscn")

var popups = [
	win.instance(),
	win.instance()
]
enum {
	WELCOME,
	CHAR_SHEET
}

# Called when the node enters the scene tree for the first time.
func _ready():
	#var welcome_win = win.instance()
	popups[WELCOME].set_title("Welcome!")
	popups[WELCOME].find_node("Text").text = "Welcome to the game!"
	#popups.push_back(welcome_win)
	
	popups[CHAR_SHEET].set_title("Character Sheet")
	
	add_child(popups[WELCOME])
	add_child(popups[CHAR_SHEET])
	popups[WELCOME].popup()
	pass # Replace with function body.
	
func _character_sheet(p):
	var list = popups[CHAR_SHEET].find_node("ItemList")
	list.clear()
	list.add_item("Name   | " + p.displayName)
	list.add_item("Health | " + str(p.hp))
	popups[CHAR_SHEET].popup()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_TextureButton_pressed():
	_character_sheet(Global.player_node)
	pass # Replace with function body.
