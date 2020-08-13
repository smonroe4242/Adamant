extends KinematicBody2D
class_name ServerActor
var actor_map : Dictionary
var monster_map : Dictionary
var username : String
var level : int = 1
remote var velocity : Vector2 = Vector2(0, 0)
remote var animation : String = "idle"
remote var left_flip : bool= false
remote var hp : int = 59
remote var max_hp : int = 59
remote var blocking : bool = false
remote var coords : Vector2
remote var puppet_position : Vector2
remote var puppet_velocity : Vector2 = Vector2(0, 0)
remote var puppet_animation : String
remote var puppet_left_flip : bool
remote var puppet_hp : int
remote var puppet_max_hp : int
remote var puppet_blocking : bool
remote var puppet_coords : Vector2

func set_puppet_vars(id: int):
	if puppet_position != position:
#		print("Server: ", name, ": telling ", id, "that position changed: ", position, ", ", puppet_position)
		rset_unreliable_id(id, 'puppet_position', position)
	if puppet_animation != animation:
#		print("Server: ", name, ": telling ", id, "that animation changed from ", puppet_animation, " to ", animation)
		rset_id(id, 'puppet_animation', animation)
	if puppet_left_flip != left_flip:
#		print("Server: ", name, ": telling ", id, "that left_flip changed")
		rset_id(id, 'puppet_left_flip', left_flip)
	if puppet_max_hp != max_hp:
#		print("Server: ", name, ": telling ", id, "that max_hp changed to ", max_hp)
		rset_id(id, 'puppet_max_hp', max_hp)
	if puppet_hp != hp:
#		print("Server: ", name, ": telling ", id, "that hp changed to ", hp)
		rset_id(id, 'puppet_hp', hp)
	if puppet_blocking != blocking:
#		print("Server: ", name, ": telling ", id, "that blocking changed to ", blocking)
		rset_id(id, 'puppet_blocking', blocking)

remote func request_damage(target):
	# a naively trusting damage calculation
	var child = get_parent().get_node(str(target))
	if not child == null:
		if child.blocking == false:
#			print("Server: damaging child: ", child.name)
			child.damage(30, get_tree().get_rpc_sender_id())
	else:
		print("Server: Child ", target, " was not found")

func damage(amt: int, player: int) -> void:
	if (hp - amt <= 0):
		hp = 0
		rpc("damage", hp)
		rpc("die")
		die()
		get_parent().get_node(str(player)).earn_xp(10 * level)
	else:
		hp -= amt
		rpc("damage", amt)

func die():
	# Implemented in subclasses
	pass
