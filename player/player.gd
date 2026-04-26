extends CharacterBody3D

# --- Nodes ---
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var aim_ray = $CameraPivot/Camera3D/AimRay
@onready var gun_pivot = $PlayerModel/GunPivot
@onready var muzzle = $PlayerModel/GunPivot/Muzzle

# --- Movement ---
const SPEED = 6.0
const GRAVITY = 20.0

# --- Camera ---
const MOUSE_SENS = 0.003
const PITCH_MIN = -0.6
const PITCH_MAX = 0.5
var pitch = 0.0

# --- OTS Camera offsets ---
const CAM_RIGHT = Vector3(0.7, 0.3, 2.8)
const CAM_LEFT  = Vector3(-0.7, 0.3, 2.8)
const CAM_AIM   = Vector3(0.4, 0.2, 1.6)
var shoulder_right = true
var is_aiming = false
var cam_target = Vector3(0.7, 0.3, 2.8)

# --- Shooting ---
const FIRE_RATE = 0.3
var can_shoot = true
var projectile_scene = preload("res://projectile/projectile.tscn")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS)
		pitch = clamp(pitch - event.relative.y * MOUSE_SENS, PITCH_MIN, PITCH_MAX)
		camera_pivot.rotation.x = pitch

	if event.is_action_pressed("switch_shoulder"):
		shoulder_right = !shoulder_right

func _physics_process(delta):
	# --- Gravity ---
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# --- Movement ---
	var input = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	var forward = -global_transform.basis.z
	var right = global_transform.basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	var move_dir = (forward * -input.y + right * input.x)
	if move_dir.length() > 0:
		move_dir = move_dir.normalized()

	velocity.x = move_dir.x * SPEED
	velocity.z = move_dir.z * SPEED
	move_and_slide()

	# --- Camera offset smooth switch ---
	is_aiming = Input.is_action_pressed("aim")
	if is_aiming:
		cam_target = CAM_AIM
	elif shoulder_right:
		cam_target = CAM_RIGHT
	else:
		cam_target = CAM_LEFT
	camera.position = camera.position.lerp(cam_target, 10.0 * delta)

	# --- Gun aims at crosshair target ---
	_aim_gun()

	# --- Shooting ---
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()
		can_shoot = false
		await get_tree().create_timer(FIRE_RATE).timeout
		can_shoot = true

func _aim_gun():
	var target_point : Vector3

	if aim_ray.is_colliding():
		# Aim at whatever the crosshair is hitting
		target_point = aim_ray.get_collision_point()
	else:
		# Aim far ahead in camera direction
		target_point = camera.global_position + \
			(-camera.global_transform.basis.z * 100.0)

	# Rotate gun smoothly towards target
	var gun_world_pos = gun_pivot.global_position
	var aim_dir = (target_point - gun_world_pos).normalized()

	if aim_dir.length() > 0.01:
		var target_basis = Basis.looking_at(aim_dir, Vector3.UP)
		gun_pivot.global_transform.basis = gun_pivot.global_transform.basis.slerp(
			target_basis, 20.0 * get_physics_process_delta_time()
		)

func shoot():
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	projectile.global_position = muzzle.global_position

	if aim_ray.is_colliding():
		var hit_point = aim_ray.get_collision_point()
		projectile.direction = (hit_point - muzzle.global_position).normalized()
	else:
		projectile.direction = -camera.global_transform.basis.z
