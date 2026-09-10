class_name MainMenu
extends Control

@onready var title_label: Label = %TitleLabel
@onready var login_button: Button = %LoginButton
@onready var register_button: Button = %RegisterButton
@onready var leaderboard_button: Button = %LeaderboardButton
@onready var quit_button: Button = %QuitButton
@onready var language_option: OptionButton = %LanguageOption

var _languages: Array = []


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_populate_language_option()
	_refresh_text()
	Localization.language_changed.connect(func(_code: String) -> void: _refresh_text())

	login_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/login_screen.tscn"))
	register_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/register_screen.tscn"))
	leaderboard_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/ui/leaderboard_screen.tscn"))
	quit_button.pressed.connect(func() -> void: get_tree().quit())


func _populate_language_option() -> void:
	language_option.clear()
	_languages = Localization.available_languages()
	for i in range(_languages.size()):
		language_option.add_item(str(_languages[i]).to_upper(), i)
		if _languages[i] == Localization.current_language:
			language_option.select(i)
	language_option.item_selected.connect(_on_language_selected)


func _on_language_selected(index: int) -> void:
	Localization.set_language(_languages[index])


func _refresh_text() -> void:
	title_label.text = Localization.get_string("menu.title")
	login_button.text = Localization.get_string("menu.login")
	register_button.text = Localization.get_string("menu.register")
	leaderboard_button.text = Localization.get_string("menu.leaderboard")
	quit_button.text = Localization.get_string("menu.quit")
