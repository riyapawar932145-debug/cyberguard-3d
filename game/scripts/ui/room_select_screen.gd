class_name RoomSelectScreen
extends Control
## Post-login hub: pick a room to enter, see per-room accuracy, or jump to the leaderboard.

const ROOMS: Array[String] = [
	"phishing_inbox",
	"upi_otp_kiosk",
	"fake_login_corridor",
	"password_vault_lab",
	"safe_browsing_street",
]

const ROOM_SCENES: Dictionary = {
	"phishing_inbox": "res://scenes/rooms/phishing_inbox/phishing_inbox.tscn",
	"upi_otp_kiosk": "res://scenes/rooms/upi_otp_kiosk/upi_otp_kiosk.tscn",
	"fake_login_corridor": "res://scenes/rooms/fake_login_corridor/fake_login_corridor.tscn",
	"password_vault_lab": "res://scenes/rooms/password_vault_lab/password_vault_lab.tscn",
	"safe_browsing_street": "res://scenes/rooms/safe_browsing_street/safe_browsing_street.tscn",
}

@onready var username_label: Label = %UsernameLabel
@onready var trust_label: Label = %TrustLabel
@onready var room_list: VBoxContainer = %RoomList
@onready var leaderboard_button: Button = %LeaderboardButton
@onready var logout_button: Button = %LogoutButton
@onready var error_label: Label = %ErrorLabel

var _accuracy_labels: Dictionary = {}


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	error_label.visible = false

	if not SessionState.is_logged_in():
		get_tree().change_scene_to_file("res://scenes/ui/login_screen.tscn")
		return

	username_label.text = SessionState.username
	trust_label.text = "%s: %d" % [Localization.get_string("hud.trust_score"), SessionState.trust_score]

	_build_room_buttons()

	leaderboard_button.text = Localization.get_string("menu.leaderboard")
	leaderboard_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/leaderboard_screen.tscn"))
	logout_button.text = Localization.get_string("menu.logout")
	logout_button.pressed.connect(_on_logout_pressed)

	ApiClient.progress_loaded.connect(_on_progress_loaded)
	ApiClient.request_failed.connect(_on_request_failed)
	ApiClient.load_progress(SessionState.user_id)


func _exit_tree() -> void:
	if ApiClient.progress_loaded.is_connected(_on_progress_loaded):
		ApiClient.progress_loaded.disconnect(_on_progress_loaded)
	if ApiClient.request_failed.is_connected(_on_request_failed):
		ApiClient.request_failed.disconnect(_on_request_failed)


func _build_room_buttons() -> void:
	for child in room_list.get_children():
		child.queue_free()
	_accuracy_labels.clear()

	for room in ROOMS:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var button: Button = Button.new()
		button.text = Localization.get_string("rooms." + room)
		button.custom_minimum_size = Vector2(320, 44)
		button.pressed.connect(_on_room_pressed.bind(room))
		row.add_child(button)

		var accuracy_label: Label = Label.new()
		accuracy_label.text = ""
		row.add_child(accuracy_label)
		_accuracy_labels[room] = accuracy_label

		room_list.add_child(row)


func _on_room_pressed(room: String) -> void:
	var path: String = str(ROOM_SCENES.get(room, ""))
	if path != "":
		get_tree().change_scene_to_file(path)


func _on_progress_loaded(progress: Dictionary) -> void:
	for room in ROOMS:
		var stats: Dictionary = progress.get(room, {})
		var label: Label = _accuracy_labels.get(room)
		if label == null:
			continue
		var completed: int = int(stats.get("completed", 0))
		if completed == 0:
			label.text = ""
		else:
			label.text = "%d%%  (%d)" % [int(stats.get("accuracy_pct", 0)), completed]


func _on_request_failed(_context: String, message: String) -> void:
	error_label.text = message
	error_label.visible = true


func _on_logout_pressed() -> void:
	SessionState.log_out()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
