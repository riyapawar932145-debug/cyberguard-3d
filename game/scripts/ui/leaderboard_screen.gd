class_name LeaderboardScreen
extends Control

@onready var title_label: Label = %TitleLabel
@onready var rows_container: VBoxContainer = %RowsContainer
@onready var empty_label: Label = %EmptyLabel
@onready var back_button: Button = %BackButton
@onready var error_label: Label = %ErrorLabel


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	error_label.visible = false
	empty_label.visible = false
	title_label.text = Localization.get_string("leaderboard.title")
	back_button.text = Localization.get_string("common.back")
	back_button.pressed.connect(_on_back_pressed)

	ApiClient.leaderboard_loaded.connect(_on_leaderboard_loaded)
	ApiClient.request_failed.connect(_on_request_failed)
	ApiClient.load_leaderboard()


func _exit_tree() -> void:
	if ApiClient.leaderboard_loaded.is_connected(_on_leaderboard_loaded):
		ApiClient.leaderboard_loaded.disconnect(_on_leaderboard_loaded)
	if ApiClient.request_failed.is_connected(_on_request_failed):
		ApiClient.request_failed.disconnect(_on_request_failed)


func _on_back_pressed() -> void:
	if SessionState.is_logged_in():
		get_tree().change_scene_to_file("res://scenes/ui/room_select_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_leaderboard_loaded(entries: Array) -> void:
	for child in rows_container.get_children():
		child.queue_free()

	empty_label.visible = entries.is_empty()
	if empty_label.visible:
		empty_label.text = Localization.get_string("leaderboard.empty")

	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)

		var rank_label: Label = Label.new()
		rank_label.text = "#%d" % (i + 1)
		rank_label.custom_minimum_size = Vector2(50, 0)
		row.add_child(rank_label)

		var name_label: Label = Label.new()
		name_label.text = str(entry.get("username", ""))
		name_label.custom_minimum_size = Vector2(220, 0)
		row.add_child(name_label)

		var score_label: Label = Label.new()
		score_label.text = str(entry.get("trust_score", 0))
		row.add_child(score_label)

		rows_container.add_child(row)


func _on_request_failed(_context: String, message: String) -> void:
	error_label.text = message
	error_label.visible = true
