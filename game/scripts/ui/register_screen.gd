class_name RegisterScreen
extends Control

const EMAIL_REGEX_PATTERN: String = "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"

@onready var title_label: Label = %TitleLabel
@onready var username_edit: LineEdit = %UsernameEdit
@onready var email_edit: LineEdit = %EmailEdit
@onready var password_edit: LineEdit = %PasswordEdit
@onready var confirm_edit: LineEdit = %ConfirmEdit
@onready var submit_button: Button = %SubmitButton
@onready var switch_button: Button = %SwitchButton
@onready var back_button: Button = %BackButton
@onready var error_label: Label = %ErrorLabel

var _email_regex: RegEx = RegEx.new()


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_email_regex.compile(EMAIL_REGEX_PATTERN)
	error_label.visible = false
	_refresh_text()

	submit_button.pressed.connect(_on_submit_pressed)
	switch_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/login_screen.tscn"))
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn"))

	ApiClient.register_success.connect(_on_register_success)
	ApiClient.register_failed.connect(_on_register_failed)
	ApiClient.request_failed.connect(_on_request_failed)


func _exit_tree() -> void:
	if ApiClient.register_success.is_connected(_on_register_success):
		ApiClient.register_success.disconnect(_on_register_success)
	if ApiClient.register_failed.is_connected(_on_register_failed):
		ApiClient.register_failed.disconnect(_on_register_failed)
	if ApiClient.request_failed.is_connected(_on_request_failed):
		ApiClient.request_failed.disconnect(_on_request_failed)


func _refresh_text() -> void:
	title_label.text = Localization.get_string("register.title")
	username_edit.placeholder_text = Localization.get_string("register.username")
	email_edit.placeholder_text = Localization.get_string("register.email")
	password_edit.placeholder_text = Localization.get_string("register.password")
	confirm_edit.placeholder_text = Localization.get_string("register.confirm_password")
	submit_button.text = Localization.get_string("register.submit")
	switch_button.text = Localization.get_string("register.switch_to_login")
	back_button.text = Localization.get_string("common.back")


func _on_submit_pressed() -> void:
	var username: String = username_edit.text.strip_edges()
	var email: String = email_edit.text.strip_edges()
	var password: String = password_edit.text
	var confirm: String = confirm_edit.text

	if username == "" or email == "" or password == "" or confirm == "":
		_show_error(Localization.get_string("register.error_empty_fields"))
		return
	if not _email_regex.search(email):
		_show_error(Localization.get_string("register.error_invalid_email"))
		return
	if password != confirm:
		_show_error(Localization.get_string("register.error_password_mismatch"))
		return

	_show_error("")
	ApiClient.register(username, email, password)


func _on_register_success(_user: Dictionary) -> void:
	error_label.modulate = Color(0.35, 0.85, 0.45)
	error_label.text = Localization.get_string("register.success")
	error_label.visible = true
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file("res://scenes/ui/login_screen.tscn")


func _on_register_failed(message: String) -> void:
	error_label.modulate = Color(0.9, 0.32, 0.32)
	_show_error(message)


func _on_request_failed(_context: String, message: String) -> void:
	error_label.modulate = Color(0.9, 0.32, 0.32)
	_show_error(message)


func _show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = message != ""
