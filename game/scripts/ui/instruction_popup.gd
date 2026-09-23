class_name InstructionPopup
extends Control
## The Training Officer's briefing, shown automatically every time a player enters a room (see
## RoomBase's `instruction_key` export). Deliberately shown every visit rather than only the
## first, since "have I seen this before" tracking adds complexity for little benefit here.
##
## Renders as a speech bubble that tracks the Officer NPC's position on screen (with a pointer
## tail toward them) rather than a generic centered dialog, so it visually reads as that
## character actually speaking instead of a disconnected system message.

@onready var bubble: Control = %Bubble
@onready var tail: Polygon2D = %Tail
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var continue_button: Button = %ContinueButton

var _callback: Callable = Callable()
var _follow_target: Node3D = null
var _camera: Camera3D = null

const BUBBLE_OFFSET_ABOVE: float = 2.2
const BUBBLE_MARGIN_BELOW: float = 14.0


func _ready() -> void:
	visible = false
	set_process(false)
	title_label.text = Localization.get_string("instruction.title_prefix")
	continue_button.text = Localization.get_string("instruction.continue")
	continue_button.pressed.connect(_on_continue_pressed)


## follow_target: the NPC's Node3D to anchor the speech bubble above - pass null to just
## center the bubble on screen instead (used where no NPC is available).
func open(instruction_key: String, follow_target: Node3D = null, on_continue: Callable = Callable()) -> void:
	_callback = on_continue
	body_label.text = Localization.get_string(instruction_key)
	_follow_target = follow_target
	_camera = get_viewport().get_camera_3d()

	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if _follow_target and _camera:
		tail.visible = true
		set_process(true)
		_update_position()
	else:
		tail.visible = false
		set_process(false)
		_center_bubble()


func _process(_delta: float) -> void:
	_update_position()


func _center_bubble() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	bubble.position = (viewport_size - bubble.size) / 2.0


func _update_position() -> void:
	if not _camera or not _follow_target or not is_instance_valid(_follow_target):
		return

	var head_pos: Vector3 = _follow_target.global_position + Vector3(0, BUBBLE_OFFSET_ABOVE, 0)

	if _camera.is_position_behind(head_pos):
		bubble.visible = false
		tail.visible = false
		return

	bubble.visible = true
	tail.visible = true

	var screen_pos: Vector2 = _camera.unproject_position(head_pos)
	var target_x: float = clampf(screen_pos.x - bubble.size.x / 2.0, 12.0, get_viewport_rect().size.x - bubble.size.x - 12.0)
	var target_y: float = maxf(screen_pos.y - bubble.size.y - BUBBLE_MARGIN_BELOW, 12.0)
	bubble.position = Vector2(target_x, target_y)

	# Tail points from the bubble's bottom edge toward the NPC's actual screen position.
	tail.position = Vector2(clampf(screen_pos.x, bubble.position.x + 10.0, bubble.position.x + bubble.size.x - 10.0), bubble.position.y + bubble.size.y)


func _on_continue_pressed() -> void:
	visible = false
	set_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var callback: Callable = _callback
	_callback = Callable()
	if callback.is_valid():
		callback.call()
