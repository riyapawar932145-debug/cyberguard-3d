class_name AvatarController
extends CharacterBody3D
## Third-person hub controller: mouse orbits a SpringArm3D camera around the character; WASD
## moves relative to the camera's yaw (not its pitch, so looking up/down never tilts movement);
## the character's Model visually turns to face its current movement direction. Deliberately
## separate from the first-person Player controller used inside every room - the hub and the
## rooms intentionally use different perspectives (see project README).

@export var move_speed: float = 5.0
@export var jump_velocity: float = 6.0
@export var mouse_sensitivity: float = 0.003
@export var turn_speed: float = 10.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var model: Node3D = $Model

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var _yaw: float = 0.0
var _pitch: float = 0.0
var _walk_time: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -0.7, 0.5)
		camera_pivot.rotation.y = _yaw
		camera_pivot.rotation.x = _pitch

	# Tab (not Esc) toggles mouse release - see Player._unhandled_input() for why. A left-click
	# while the mouse is free also recaptures it (covers losing it other ways, e.g. tabbing away).
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		var capture: bool = Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE)
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	).normalized()

	# Yaw-only basis for movement so looking up/down (pitch) never affects walk direction.
	var yaw_basis: Basis = Basis(Vector3.UP, _yaw)
	var direction: Vector3 = yaw_basis * Vector3(input_dir.x, 0.0, input_dir.y)
	direction.y = 0.0
	direction = direction.normalized()

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	if direction.length() > 0.1:
		var target_angle: float = atan2(direction.x, direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, turn_speed * delta)
		_walk_time += delta * 8.0
		model.position.y = absf(sin(_walk_time)) * 0.06
	else:
		_walk_time = 0.0
		model.position.y = lerpf(model.position.y, 0.0, 10.0 * delta)

	move_and_slide()
