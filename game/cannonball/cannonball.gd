extends RigidBody2D

func _ready() -> void:
	$Timer.connect("timeout", self, "on_timeout")

func on_timeout():
	queue_free()
