extends RigidBody2D

const HP_LOST_PER_CBALL = 10
var health = 100

func _ready() -> void:
	$Timer.connect("timeout", self, "on_timeout")


func _physics_process(_delta: float) -> void:
	var bodies := get_colliding_bodies()
	for b in bodies:
		if b.is_in_group("cball"):
			b.queue_free()
			health -= HP_LOST_PER_CBALL
	
	$ProgressBar.value = health
	
	if health <= 0:
		queue_free()


func on_timeout():
	queue_free()
