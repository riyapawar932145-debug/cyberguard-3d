class_name LoginScreen
extends Control

@onready var title_label: Label = %TitleLabel
@onready var username_edit: LineEdit = %UsernameEdit
@onready var password_edit: LineEdit = %PasswordEdit
@onready var submit_button: Button = %SubmitButton
@onready var switch_button: Button = %SwitchButton
@onready var back_button: Button = %BackButton
@onready var error_label: Label = %ErrorLabel


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	error_label.visible = false
	_refresh_text()

	submit_button.pressed.connect(_on_submit_pressed)
	switch_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/register_screen.tscn"))
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))

	ApiClient.login_success.connect(_on_login_success)
	ApiClient.login_failed.connect(_on_login_failed)
	ApiClient.request_failed.connect(_on_request_failed)


func _exit_tree() -> void:
	if ApiClient.login_success.is_connected(_on_login_success):
		ApiClient.login_success.disconnect(_on_login_success)
	if ApiClient.login_failed.is_connected(_on_login_failed):
		ApiClient.login_failed.disconnect(_on_login_failed)
	if ApiClient.request_failed.is_connected(_on_request_failed):
		ApiClient.request_failed.disconnect(_on_request_failed)


func _refresh_text() -> void:
	title_label.text = Localization.get_string("login.title")
	username_edit.placeholder_text = Localization.get_string("login.username")
	password_edit.placeholder_text = Localization.get_string("login.password")
	submit_button.text = Localization.get_string("login.submit")
	switch_button.text = Localization.get_string("login.switch_to_register")
	back_button.text = Localization.get_string("common.back")


func _on_submit_pressed() -> void:
	var username: String = username_edit.text.strip_edges()
	var password: String = password_edit.text

	if username == "" or password == "":
		_show_error(Localization.get_string("register.error_empty_fields"))
		return

	_show_error("")
	ApiClient.login(username, password)


func _on_login_success(user: Dictionary) -> void:
	SessionState.set_user(user)
	Localization.set_language(str(user.get("preferred_language", "en")))
	get_tree().change_scene_to_file("res://scenes/ui/room_select_screen.tscn")


func _on_login_failed(message: String) -> void:
	_show_error(message)


func _on_request_failed(_context: String, message: String) -> void:
	_show_error(message)


func _show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = message != ""
