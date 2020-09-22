extends AudioStreamPlayer

var bgm = load("res://assets/sound/07 We're the Resistors.wav")
var ui_hover = load("res://assets/sound/rpg_sound_pack/RPG Sound Pack/interface/interface1.wav")
var ui_confirm = load("res://assets/sound/rpg_sound_pack/RPG Sound Pack/battle/sword-unsheathe.wav")
var sfx_node
var swing = load("res://assets/sound/rpg_sound_pack/RPG Sound Pack/battle/swing.wav")


# Called when the node enters the scene tree for the first time.
func _ready():
	set_stream(bgm)
	play()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _enter_tree():
	sfx_node = get_child(0)

func play_confirm():
	sfx_node.set_stream(ui_confirm)
	sfx_node.play()

func play_swing():
	sfx_node.set_stream(swing)
	sfx_node.play()
