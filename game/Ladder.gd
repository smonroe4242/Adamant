extends Area2D
class_name Ladder

func _on_Ladder_body_entered(body):
	if not body.get("onLadder") == null:
		body.onLadder += 1

func _on_Ladder_body_exited(body):
	if not body.get("onLadder") == null:
		body.onLadder -= 1
