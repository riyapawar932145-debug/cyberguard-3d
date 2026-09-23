class_name StartScreen
extends Control
## Post-login landing screen. Room selection itself now happens by walking through the 3D hub
## ("Cyber City") - this screen is just Start / Leaderboard / Logout. Kept the filename
## `room_select_screen` (referenced from login_screen.gd and elsewhere) to avoid a repo-wide
## rename; the class is what actually changed.

@onready var username_label: Label = %UsernameLabel
@onready var trust_label: Label = %TrustLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var start_button: Button = %StartButton
@onready var leaderboard_button: Button = %LeaderboardButton
@onready var logout_button: Button = %LogoutButton
@onready var error_label: Label = %ErrorLabel


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	error_label.visible = false

	if not SessionState.is_logged_in():
		get_tree().change_scene_to_file("res://scenes/ui/login_screen.tscn")
		return

	username_label.text = SessionState.username
	trust_label.text = "%s (%s: %d)" % [
		SessionState.get_level_title(),
		Localization.get_string("hud.trust_score"),
		SessionState.trust_score,
	]
	subtitle_label.text = Localization.get_string("start.subtitle")
	start_button.text = Localization.get_string("start.begin")
	leaderboard_button.text = Localization.get_string("menu.leaderboard")
	logout_button.text = Localization.get_string("menu.logout")

	start_button.pressed.connect(_on_start_pressed)
	leaderboard_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/leaderboard_screen.tscn"))
	logout_button.pressed.connect(_on_logout_pressed)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/avatar_select_screen.tscn")


func _on_logout_pressed() -> void:
	SessionState.log_out()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
