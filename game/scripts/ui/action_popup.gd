class_name ActionPopup
extends Control
## Context-appropriate action buttons for whatever object the player just clicked.
## Button set differs per object type - the room passes in options, this just renders them.

@onready var title_label: Label = %TitleLabel
@onready var button_container: VBoxContainer = %ButtonContainer

var _callback: Callable = Callable()


func _ready() -> void:
	visible = false


## options: Array of {"action": String, "label_key": String}
func open(title: String, options: Array, on_chosen: Callable) -> void:
	_callback = on_chosen
	title_label.text = title

	for child in button_container.get_children():
		child.queue_free()

	for option in options:
		var button: Button = Button.new()
		button.text = Localization.get_string(str(option.get("label_key", "")))
		button.pressed.connect(_on_option_pressed.bind(str(option.get("action", ""))))
		button_container.add_child(button)

	visible = true
	_release_mouse()


## The mode switch is triggered by the same left-click that's still being processed as the
## "interact" input event; changing MOUSE_MODE while a mouse button event is mid-flight doesn't
## reliably show the OS cursor on Windows. Waiting until that event has fully resolved fixes it.
func _release_mouse() -> void:
	await get_tree().create_timer(0.1).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_option_pressed(action: String) -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var callback: Callable = _callback
	_callback = Callable()
	if callback.is_valid():
		callback.call(action)
