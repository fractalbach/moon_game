extends Node2D

onready var player: RigidBody2D = get_node("Player")
onready var gun: AnimatedSprite = get_node("player_gun")
onready var gun_flame: AnimatedSprite = get_node("player_gun/gun_flame")
onready var debug: Label = get_node("CanvasLayer/MarginContainer/HBoxContainer/MarginContainer/debug")
onready var hp_bar: ProgressBar = get_node("CanvasLayer/MarginContainer/HBoxContainer/ProgressBar")

var cannonball = preload("res://cannonball/cannonball.tscn")
var asteroid = preload("res://asteroid/asteroid.tscn")
var rng = RandomNumberGenerator.new()

const thrust = Vector2(10, 0)
const launch = Vector2(400, 0)
const COOLDOWN_AFTER_FLAME = 5
const COOLDOWN_AFTER_ROCKET = 5
const MINIMUM_Y_POSITION = 500
const HP_LOST_PER_ASTEROID = 10
const MAX_VELOCITY = 400

var cooldown = 0
var health = 100


func _ready() -> void:
	$AsteroidSpawnTimer.connect("timeout", self, "on_asteroid_spawn_timer")
	rng.randomize()


func _process(_delta: float) -> void:
	point_gun_toward_mouse()
	gun_flame.visible = Input.is_action_pressed("flame")
	
	debug.text = "DEBUG INFO \n" \
		+ "player_position:  " + str(player.position.round()) + "\n" \
		+ "linear_velocity:  " + str(player.linear_velocity.round()) + "\n" \
		+ "angular_velocity: " + str(player.angular_velocity) + "\n" \
		+ "asteroid_timer:   " + str(stepify($AsteroidSpawnTimer.time_left, 0.1)) + "\n"



func _physics_process(delta: float) -> void:
	cooldown = max(0, cooldown - 1)
	
	if Input.is_action_pressed("flame") and cooldown <= 0:
		cooldown = COOLDOWN_AFTER_FLAME
		player.apply_central_impulse(thrust.rotated(gun.rotation + PI))
	
	
	if Input.is_action_pressed("rocket") and cooldown <= 0:
		cooldown = COOLDOWN_AFTER_ROCKET
		var cball = cannonball.instance()
		cball.position = player.position + 45 * Vector2(1,0).rotated(gun.rotation)
		cball.linear_velocity = player.linear_velocity
		cball.apply_central_impulse(launch.rotated(gun.rotation))
		cball.add_torque(500 * randf())
		# player.apply_central_impulse(0.5 * launch.rotated(gun.rotation + PI))
		add_child(cball)
	
	if player.linear_velocity.length() > MAX_VELOCITY:
		player.linear_velocity = player.linear_velocity.normalized() * 200
	
	var bodies := player.get_colliding_bodies()
	for b in bodies:
		if b.is_in_group("asteroid"):
			health -= 100 * (b.linear_velocity.length() / 800)
			# b.queue_free()
	
	update_hp_bar()
	handle_death()
	debug_update_line()


func handle_death():
	if player.position.y > 500 or health <= 0:
		health = 100
		player.linear_velocity = Vector2()
		player.position = Vector2() # Respawn

func point_gun_toward_mouse():
	gun.position = player.position
	var mouse_pos = get_global_mouse_position()
	var my_pos = player.global_position
	gun.rotation = (mouse_pos - my_pos).angle()


func debug_update_line():
	$debug_velocity.position = player.position
	$debug_velocity.points[1] = 100 * player.linear_velocity.normalized()

func update_hp_bar():
	hp_bar.value = health


func on_asteroid_spawn_timer():
	spawn_asteroid()
	$AsteroidSpawnTimer.wait_time = 5 # randf()*5
	pass


func spawn_asteroid():
	var ast = asteroid.instance()
	
	# Spawn the asteroid somewhere in front and above of the player
	var x = rng.randf_range(0, 400)
	var y = rng.randf_range(-400, -500)
	ast.position = player.position + Vector2(x,y)
	
	# starting velocity will be the same as player, to keep you on your toes!
	ast.linear_velocity = player.linear_velocity
	
	# Send the asteroid toward the player
	var f_magnitude = rng.randf_range(0, 200) + 200
	var f_unit = ast.position.direction_to(player.position)
	ast.apply_central_impulse(f_magnitude * f_unit)
	
	# Apply some spin to the asteroid randomly, and add it to the tree
	ast.add_torque(500 * randf())
	add_child(ast)
	print("spawned pos-player= ", Vector2(x,y), " with v= ", ast.linear_velocity.round())

