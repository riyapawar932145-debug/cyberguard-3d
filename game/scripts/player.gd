class_name Player
extends CharacterBody3D
## First-person WASD + mouse-look controller. Left-click raycasts 5m from the camera
## and, on a hit, hands the object off to the active room controller (group "room_controller").

@export var move_speed: float = 4.5
@export var jump_velocity: float = 6.0
@export var mouse_sensitivity: float = 0.0025
@export var interact_range: float = 5.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var _pitch: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interact_ray.target_position = Vector3(0.0, 0.0, -interact_range)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.4, 1.4)
		head.rotation.x = _pitch

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		var capture: bool = Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("interact"):
		_try_interact()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	).normalized()

	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	move_and_slide()


func _try_interact() -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if not interact_ray.is_colliding():
		return

	var collider: Object = interact_ray.get_collider()
	if collider == null or not collider.has_method("get_action_options"):
		return

	var room: Node = get_tree().get_first_node_in_group("room_controller")
	if room and room.has_method("on_object_clicked"):
		room.on_object_clicked(collider)
