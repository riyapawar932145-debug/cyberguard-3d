class_name AvatarSelectScreen
extends Control
## Reached from the Start screen, before entering the hub. Picks SessionState.avatar_gender,
## which hub_world.gd reads to decide which avatar scene to spawn.

@onready var title_label: Label = %TitleLabel
@onready var man_button: Button = %ManButton
@onready var woman_button: Button = %WomanButton
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton
@onready var man_check: Label = %ManCheck
@onready var woman_check: Label = %WomanCheck

var _selected: String = "man"


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	title_label.text = Localization.get_string("avatar.title")
	man_button.text = Localization.get_string("avatar.man")
	woman_button.text = Localization.get_string("avatar.woman")
	confirm_button.text = Localization.get_string("avatar.confirm")
	back_button.text = Localization.get_string("common.back")

	_selected = SessionState.avatar_gender
	_refresh_selection()

	man_button.pressed.connect(_on_select.bind("man"))
	woman_button.pressed.connect(_on_select.bind("woman"))
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/room_select_screen.tscn"))


func _on_select(gender: String) -> void:
	_selected = gender
	_refresh_selection()


func _refresh_selection() -> void:
	man_check.visible = _selected == "man"
	woman_check.visible = _selected == "woman"


func _on_confirm_pressed() -> void:
	SessionState.avatar_gender = _selected
	get_tree().change_scene_to_file("res://scenes/hub/hub_world.tscn")
