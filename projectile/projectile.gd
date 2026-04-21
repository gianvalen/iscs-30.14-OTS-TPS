extends Area3D

const SPEED = 40.0
const MAX_DISTANCE = 200.0

var direction = Vector3.FORWARD
var start_position = Vector3.ZERO

func _ready():
	start_position = global_position
	# Connect the body_entered signal for collision
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	# Move projectile forward each frame (short raycast-style steps)
	var move_amount = direction * SPEED * delta
	global_position += move_amount

	# Destroy if travelled too far
	if global_position.distance_to(start_position) > MAX_DISTANCE:
		queue_free()

func _on_body_entered(body):
	# Hit terrain or static object
	if body != get_tree().get_first_node_in_group("player"):
		spawn_explosion(global_position, false)
		queue_free()

func _on_area_entered(area):
	# Hit an enemy
	if area.is_in_group("enemy"):
		area.take_hit()
		spawn_explosion(global_position, false)
		queue_free()

var explosion_scene = preload("res://explosion/explosion.tscn")

func spawn_explosion(pos, big):
	var explosion = explosion_scene.instantiate()
	get_tree().root.add_child(explosion)
	explosion.global_position = pos
	explosion.init(big)
