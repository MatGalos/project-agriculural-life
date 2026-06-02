extends CharacterBody3D

@export var speed := 4.0
@export var sprint_speed := 6.0
@export var gravity := 20.0
@export var mouse_sensitivity := 0.003
@export var camera_distance := 4.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var pitch := 0.0

func _ready():
	camera_pivot.position = Vector3(0, 1.4, 0)
	camera_pivot.rotation = Vector3.ZERO

	camera.position = Vector3(0, 0.5, camera_distance)
	camera.rotation = Vector3.ZERO
	camera.current = true


func _input(event):
	if event is InputEventMouseMotion:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)

		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-45), deg_to_rad(35))
		camera_pivot.rotation.x = pitch


func _physics_process(delta):
	var input_dir := InputManager.get_move_vector()

	var forward := -camera_pivot.global_transform.basis.z
	var right := camera_pivot.global_transform.basis.x

	forward.y = 0
	right.y = 0

	forward = forward.normalized()
	right = right.normalized()

	var direction := (right * input_dir.x - forward * input_dir.y).normalized()

	var current_speed := sprint_speed if InputManager.is_sprint_pressed() else speed
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	move_and_slide()
