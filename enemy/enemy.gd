extends Area3D

var health = 3
var explosion_scene = preload("res://explosion/explosion.tscn")

func _ready():
	add_to_group("enemy")

func take_hit():
	health -= 1
	# Make the enemy flash white when it gets hit
	var mesh = $MeshInstance3D
	var mat = mesh.get_active_material(0)
	mat.albedo_color = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		mat.albedo_color = Color.RED

	if health <= 0:
		die()

func die():
	var explosion = explosion_scene.instantiate()
	get_tree().root.add_child(explosion)
	explosion.global_position = global_position
	explosion.init(true)
	queue_free()
