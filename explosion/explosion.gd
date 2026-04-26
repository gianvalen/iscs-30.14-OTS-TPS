extends Node3D

var lifetime = 0.3
var timer = 0.0
var big = false

func init(is_big: bool):
	big = is_big
	if big:
		scale = Vector3(3.0, 3.0, 3.0)
	else:
		scale = Vector3(1.0, 1.0, 1.0)

func _process(delta):
	timer += delta
	# Slowly shrink the explosion over time
	var t = timer / lifetime
	scale = scale.lerp(Vector3.ZERO, t * delta * 10)

	if timer >= lifetime:
		queue_free()
