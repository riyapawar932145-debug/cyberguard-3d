class_name InstructionPopup
extends Control
## The Training Officer's briefing, shown automatically every time a player enters a room (see
## RoomBase's `instruction_key` export). Deliberately shown every visit rather than only the
## first, since "have I seen this before" tracking adds complexity for little benefit here.

@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var continue_button: Button = %ContinueButton

var _callback: Callable = Callable()


func _ready() -> void:
	visible = false
	title_label.text = Localization.get_string("instruction.title_prefix")
	continue_button.text = Localization.get_string("instruction.continue")
	continue_button.pressed.connect(_on_continue_pressed)


func open(instruction_key: String, on_continue: Callable = Callable()) -> void:
	_callback = on_continue
	body_label.text = Localization.get_string(instruction_key)
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_continue_pressed() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var callback: Callable = _callback
	_callback = Callable()
	if callback.is_valid():
		callback.call()
