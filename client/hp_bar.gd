extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not Global.player_node == null:
		$CanvasLayer/TextureProgress.max_value = Global.player_node.mhp
		$CanvasLayer/TextureProgress.set_value(Global.player_node.hp)
		$CanvasLayer/Label.text = str(str(Global.player_node.hp) + "/" + str(Global.player_node.mhp))
