class_name AdminMain
extends Control
## Scenario admin CRUD screen. Plain 2D Control, launched via `--admin` (see scripts/main.gd).
## No authentication in this build phase - see admin.no_auth_notice, shown as a banner.
## No 3D content, no Player, no "room_controller" group involvement.

const ROOMS: Array[String] = [
	"phishing_inbox",
	"upi_otp_kiosk",
	"fake_login_corridor",
	"password_vault_lab",
	"safe_browsing_street",
]

@onready var no_auth_banner_label: Label = %NoAuthBannerLabel
@onready var title_label: Label = %TitleLabel
@onready var error_label: Label = %ErrorLabel

@onready var add_button: Button = %AddButton
@onready var scenario_list: ItemList = %ScenarioList

@onready var form_title_label: Label = %FormTitleLabel
@onready var code_label: Label = %CodeLabel
@onready var code_edit: LineEdit = %CodeEdit
@onready var room_label: Label = %RoomLabel
@onready var room_option: OptionButton = %RoomOption
@onready var title_field_label: Label = %TitleFieldLabel
@onready var title_edit: LineEdit = %TitleEdit
@onready var difficulty_label: Label = %DifficultyLabel
@onready var difficulty_spin: SpinBox = %DifficultySpin
@onready var fraud_label: Label = %FraudLabel
@onready var fraud_check: CheckBox = %FraudCheck
@onready var red_flags_label: Label = %RedFlagsLabel
@onready var red_flags_edit: TextEdit = %RedFlagsEdit
@onready var correct_actions_label: Label = %CorrectActionsLabel
@onready var correct_actions_edit: LineEdit = %CorrectActionsEdit

@onready var save_button: Button = %SaveButton
@onready var cancel_button: Button = %CancelButton
@onready var delete_button: Button = %DeleteButton

var _scenarios: Array = []
var _selected_id: int = -1


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	error_label.visible = false

	no_auth_banner_label.text = Localization.get_string("admin.no_auth_notice")
	title_label.text = Localization.get_string("admin.title")

	add_button.text = Localization.get_string("admin.add")
	code_label.text = Localization.get_string("admin.field.code")
	room_label.text = Localization.get_string("admin.field.room")
	title_field_label.text = Localization.get_string("admin.field.title")
	difficulty_label.text = Localization.get_string("admin.field.difficulty")
	fraud_label.text = Localization.get_string("admin.field.is_fraud")
	red_flags_label.text = Localization.get_string("admin.field.red_flags")
	correct_actions_label.text = Localization.get_string("admin.field.correct_actions")
	save_button.text = Localization.get_string("admin.save")
	cancel_button.text = Localization.get_string("admin.cancel")
	delete_button.text = Localization.get_string("admin.delete")

	difficulty_spin.min_value = 1
	difficulty_spin.max_value = 5
	difficulty_spin.step = 1

	for room in ROOMS:
		room_option.add_item(Localization.get_string("rooms." + room))

	scenario_list.item_selected.connect(_on_item_selected)
	add_button.pressed.connect(_on_add_pressed)
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	delete_button.pressed.connect(_on_delete_pressed)

	ApiClient.admin_scenarios_loaded.connect(_on_admin_scenarios_loaded)
	ApiClient.admin_scenario_created.connect(_on_admin_scenario_created)
	ApiClient.admin_scenario_updated.connect(_on_admin_scenario_updated)
	ApiClient.admin_scenario_deleted.connect(_on_admin_scenario_deleted)
	ApiClient.admin_request_failed.connect(_on_admin_request_failed)
	ApiClient.request_failed.connect(_on_request_failed)

	_reset_form()
	ApiClient.admin_list_scenarios()


func _exit_tree() -> void:
	if ApiClient.admin_scenarios_loaded.is_connected(_on_admin_scenarios_loaded):
		ApiClient.admin_scenarios_loaded.disconnect(_on_admin_scenarios_loaded)
	if ApiClient.admin_scenario_created.is_connected(_on_admin_scenario_created):
		ApiClient.admin_scenario_created.disconnect(_on_admin_scenario_created)
	if ApiClient.admin_scenario_updated.is_connected(_on_admin_scenario_updated):
		ApiClient.admin_scenario_updated.disconnect(_on_admin_scenario_updated)
	if ApiClient.admin_scenario_deleted.is_connected(_on_admin_scenario_deleted):
		ApiClient.admin_scenario_deleted.disconnect(_on_admin_scenario_deleted)
	if ApiClient.admin_request_failed.is_connected(_on_admin_request_failed):
		ApiClient.admin_request_failed.disconnect(_on_admin_request_failed)
	if ApiClient.request_failed.is_connected(_on_request_failed):
		ApiClient.request_failed.disconnect(_on_request_failed)


func _rebuild_list() -> void:
	scenario_list.clear()
	for scenario in _scenarios:
		var fraud_flag: String = "Y" if bool(scenario.get("is_fraud", false)) else "N"
		var label: String = "%s  [%s]  %s  (d%d, fraud:%s)" % [
			str(scenario.get("code", "")),
			str(scenario.get("room", "")),
			str(scenario.get("title", "")),
			int(scenario.get("difficulty", 1)),
			fraud_flag,
		]
		scenario_list.add_item(label)


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _scenarios.size():
		return
	var scenario: Dictionary = _scenarios[index]
	_selected_id = int(scenario.get("id", -1))
	form_title_label.text = Localization.get_string("admin.edit")

	code_edit.text = str(scenario.get("code", ""))
	var room_index: int = ROOMS.find(str(scenario.get("room", "")))
	room_option.selected = max(room_index, 0)
	title_edit.text = str(scenario.get("title", ""))
	difficulty_spin.value = int(scenario.get("difficulty", 1))
	fraud_check.button_pressed = bool(scenario.get("is_fraud", false))
	red_flags_edit.text = str(scenario.get("red_flags", ""))
	correct_actions_edit.text = str(scenario.get("correct_actions", ""))

	delete_button.disabled = false


func _reset_form() -> void:
	_selected_id = -1
	form_title_label.text = Localization.get_string("admin.add")
	code_edit.text = ""
	room_option.selected = 0
	title_edit.text = ""
	difficulty_spin.value = 1
	fraud_check.button_pressed = false
	red_flags_edit.text = ""
	correct_actions_edit.text = ""
	delete_button.disabled = true
	scenario_list.deselect_all()


func _on_add_pressed() -> void:
	_reset_form()


func _on_cancel_pressed() -> void:
	_reset_form()


func _on_save_pressed() -> void:
	var data: Dictionary = {
		"code": code_edit.text.strip_edges(),
		"room": ROOMS[room_option.selected],
		"title": title_edit.text.strip_edges(),
		"difficulty": int(difficulty_spin.value),
		"is_fraud": fraud_check.button_pressed,
		"red_flags": red_flags_edit.text,
		"correct_actions": correct_actions_edit.text.strip_edges(),
	}

	_show_error("")
	if _selected_id == -1:
		ApiClient.admin_create_scenario(data)
	else:
		ApiClient.admin_update_scenario(_selected_id, data)


func _on_delete_pressed() -> void:
	if _selected_id == -1:
		return
	_show_error("")
	ApiClient.admin_delete_scenario(_selected_id)


func _on_admin_scenarios_loaded(scenarios: Array) -> void:
	_scenarios = scenarios.duplicate(true)
	_rebuild_list()


func _on_admin_scenario_created(_scenario: Dictionary) -> void:
	_reset_form()
	ApiClient.admin_list_scenarios()


func _on_admin_scenario_updated(_scenario: Dictionary) -> void:
	_reset_form()
	ApiClient.admin_list_scenarios()


func _on_admin_scenario_deleted(_scenario_id: int) -> void:
	_reset_form()
	ApiClient.admin_list_scenarios()


func _on_admin_request_failed(_context: String, message: String) -> void:
	_show_error(message)


func _on_request_failed(_context: String, message: String) -> void:
	_show_error(message)


func _show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = message != ""
