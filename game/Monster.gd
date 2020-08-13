extends Actor
class_name Monster

func _ready() -> void:
	._ready()
	sprite.set_flip_h(left_flip)
	sprite.play("run")

func _physics_process(_delta: float) -> void:
	be_a_replica(is_on_floor())
